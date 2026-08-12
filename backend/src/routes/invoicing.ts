import { Router, type IRouter } from "express";
import { eq, desc } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  invoiceTable,
  invoiceItemTable,
  invoiceTransactionTable,
  companyInfoMasterTable,
  partyMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
} from "../db/index.js";
import {
  getUninvoicedPreview,
  listUninvoicedParties,
  computeItemAmounts,
} from "../lib/invoice-engine.js";
import { isFbrSandboxEnabled } from "../lib/fbr/config.js";
import { buildFbrInvoicePayload, postInvoiceToFbr } from "../lib/fbr/client.js";

const router: IRouter = Router();

function idParam(req: { params: Record<string, string> }) {
  const id = parseInt(req.params.id, 10);
  return isNaN(id) ? null : id;
}

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

// ─── Parties with un-invoiced Fabric_Dispatch transactions ────────────────

router.get("/invoicing/parties", async (_req, res): Promise<void> => {
  const parties = await listUninvoicedParties();
  res.json(parties);
});

// ─── Aggregation preview for a party ──────────────────────────────────────
// Shows grouped items + derived amounts the user will confirm, with editable
// per-KG rates applied client-side before generation. This returns the
// grouped net weights and source transaction ids.

router.get("/invoicing/preview/:partyId", async (req, res): Promise<void> => {
  const partyId = parseInt(req.params.partyId, 10);
  if (isNaN(partyId)) { res.status(400).json({ error: "Invalid party id" }); return; }

  const { groups, transactionHeaderIds, totalNetWeight } = await getUninvoicedPreview(partyId);
  res.json({ partyId, groups, transactionHeaderIds, totalNetWeight });
});

// ─── Generate invoice ─────────────────────────────────────────────────────
// Body: { partyId, createdBy, items: [{ group..., ratePerKg }] }.
// Consumes all un-invoiced Fabric_Dispatch transactions for the party inside
// one transaction (concurrency-safe: claims via anti-join, inserts junction).

const generateBodySchema = z.object({
  partyId: z.coerce.number().int().positive("Party is required"),
  createdBy: z.string().min(1, "Enter your name"),
  items: z.array(z.object({
    yarnTypeId: z.coerce.number().int().positive(),
    yarnCountId: z.coerce.number().int().positive().optional().nullable(),
    hsCode: z.string().optional().nullable(),
    uoM: z.string().optional().nullable(),
    productDescription: z.string().optional().nullable(),
    quantity: z.coerce.number().positive("Net weight must be positive"),
    ratePerKg: z.coerce.number().positive("Rate per kg must be positive"),
  })).min(1, "At least one item is required"),
});

router.post("/invoicing/generate", async (req, res): Promise<void> => {
  const parsed = generateBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid input" });
    return;
  }
  const { partyId, createdBy, items } = parsed.data;

  // Re-resolve the un-invoiced transactions fresh (concurrency guard).
  const preview = await getUninvoicedPreview(partyId);
  if (preview.transactionHeaderIds.length === 0) {
    res.status(409).json({ error: "No un-invoiced Fabric Delivery transactions remain for this party." });
    return;
  }

  // Validate the submitted items against the real grouping (guard against a
  // stale client). We trust the summed quantities + source txs from the DB,
  // but take ratePerKg from the client.
  const rateByGroup = new Map<string, number>();
  for (const it of items) {
    rateByGroup.set(`${it.yarnTypeId}|${it.yarnCountId ?? ""}`, it.ratePerKg);
  }

  const defaultCompany = await db
    .select()
    .from(companyInfoMasterTable)
    .where(eq(companyInfoMasterTable.isDefault, true));
  if (defaultCompany.length === 0) {
    res.status(409).json({ error: "No default company is configured. Set a default company in Company Info first." });
    return;
  }
  const company = defaultCompany[0];

  const invoiceDate = todayIso();
  let invoice: typeof invoiceTable.$inferSelect;
  const itemRows: (typeof invoiceItemTable.$inferSelect)[] = [];
  let grandTotal = 0;
  let totalTax = 0;
  let totalValue = 0;
  let conflict = false;

  const result = await db.transaction(async (tx) => {
    // Re-claim: inside the transaction, verify these headers are still
    // un-invoiced by inserting junction rows; a unique violation on
    // invoice_transaction_tx_unique means a concurrent generate took one.
    const [ins] = await tx
      .insert(invoiceTable)
      .values({
        invoiceDate,
        companyId: company.id,
        partyId,
        status: "draft",
        totalValue: "0",
        totalTax: "0",
        grandTotal: "0",
        createdBy,
      })
      .returning();
    invoice = ins;

    let idx = 0;
    for (const g of preview.groups) {
      const key = `${g.yarnTypeId}|${g.yarnCountId ?? ""}`;
      const rate = rateByGroup.get(key);
      if (rate == null || !(rate > 0)) continue;
      const amounts = computeItemAmounts(g.quantity, rate);
      const parsedQty = parseFloat(g.quantity) || 0;
      totalValue += parseFloat(amounts.valueExcludingTax);
      totalTax += parseFloat(amounts.taxAmount);
      grandTotal += parseFloat(amounts.totalValue);
      const [item] = await tx
        .insert(invoiceItemTable)
        .values({
          invoiceId: ins.id,
          yarnTypeId: g.yarnTypeId,
          yarnCountId: g.yarnCountId,
          hsCode: g.hsCode,
          uoM: g.uoM,
          productDescription: g.productDescription,
          quantity: String(parsedQty),
          ratePerKg: String(rate),
          valueExcludingTax: amounts.valueExcludingTax,
          taxAmount: amounts.taxAmount,
          totalValue: amounts.totalValue,
        })
        .returning();
      itemRows.push(item);
    }

    if (itemRows.length === 0) {
      throw Object.assign(new Error("No valid items"), { code: "NO_ITEMS" });
    }

    // Claim all source transactions for this invoice (junction rows).
    await tx.insert(invoiceTransactionTable).values(
      preview.transactionHeaderIds.map((tid) => ({ invoiceId: ins.id, transactionHeaderId: tid })),
    );

    // Update the header totals.
    const [updated] = await tx
      .update(invoiceTable)
      .set({
        totalValue: totalValue.toFixed(2),
        totalTax: totalTax.toFixed(2),
        grandTotal: grandTotal.toFixed(2),
        updatedAt: new Date(),
      })
      .where(eq(invoiceTable.id, ins.id))
      .returning();
    return updated;
  }).catch((err) => {
    if (err && (err as { code?: string }).code === "NO_ITEMS") { conflict = true; }
    if (err && (err as { code?: string }).code === "23505") { conflict = true; }
    if (conflict) return null;
    throw err;
  });

  if (conflict || !result) {
    res.status(409).json({ error: "Invoice could not be generated. Some transactions may have been invoiced by another user, or no valid items were provided." });
    return;
  }

  const detail = await loadInvoiceDetail(result.id);
  res.status(201).json(detail);
});

// ─── List invoices ────────────────────────────────────────────────────────

router.get("/invoicing", async (_req, res): Promise<void> => {
  const rows = await db
    .select({
      id: invoiceTable.id,
      invoiceDate: invoiceTable.invoiceDate,
      companyId: invoiceTable.companyId,
      companyName: companyInfoMasterTable.name,
      partyId: invoiceTable.partyId,
      partyName: partyMasterTable.name,
      status: invoiceTable.status,
      fbrInvoiceNumber: invoiceTable.fbrInvoiceNumber,
      totalValue: invoiceTable.totalValue,
      totalTax: invoiceTable.totalTax,
      grandTotal: invoiceTable.grandTotal,
      createdBy: invoiceTable.createdBy,
      createdAt: invoiceTable.createdAt,
      postedAt: invoiceTable.postedAt,
    })
    .from(invoiceTable)
    .leftJoin(companyInfoMasterTable, eq(invoiceTable.companyId, companyInfoMasterTable.id))
    .leftJoin(partyMasterTable, eq(invoiceTable.partyId, partyMasterTable.id))
    .orderBy(desc(invoiceTable.id));
  res.json(rows);
});

// ─── Single invoice detail ────────────────────────────────────────────────

async function loadInvoiceDetail(id: number) {
  const [inv] = await db
    .select({
      id: invoiceTable.id,
      invoiceDate: invoiceTable.invoiceDate,
      companyId: invoiceTable.companyId,
      companyName: companyInfoMasterTable.name,
      partyId: invoiceTable.partyId,
      partyName: partyMasterTable.name,
      status: invoiceTable.status,
      fbrInvoiceNumber: invoiceTable.fbrInvoiceNumber,
      fbrStatusCode: invoiceTable.fbrStatusCode,
      totalValue: invoiceTable.totalValue,
      totalTax: invoiceTable.totalTax,
      grandTotal: invoiceTable.grandTotal,
      createdBy: invoiceTable.createdBy,
      createdAt: invoiceTable.createdAt,
      postedAt: invoiceTable.postedAt,
    })
    .from(invoiceTable)
    .leftJoin(companyInfoMasterTable, eq(invoiceTable.companyId, companyInfoMasterTable.id))
    .leftJoin(partyMasterTable, eq(invoiceTable.partyId, partyMasterTable.id))
    .where(eq(invoiceTable.id, id));

  const items = await db
    .select({
      id: invoiceItemTable.id,
      yarnTypeId: invoiceItemTable.yarnTypeId,
      yarnTypeName: yarnTypeMasterTable.name,
      yarnCountId: invoiceItemTable.yarnCountId,
      yarnCountName: yarnCountMasterTable.count,
      hsCode: invoiceItemTable.hsCode,
      uoM: invoiceItemTable.uoM,
      productDescription: invoiceItemTable.productDescription,
      quantity: invoiceItemTable.quantity,
      ratePerKg: invoiceItemTable.ratePerKg,
      valueExcludingTax: invoiceItemTable.valueExcludingTax,
      taxAmount: invoiceItemTable.taxAmount,
      totalValue: invoiceItemTable.totalValue,
      saleType: invoiceItemTable.saleType,
    })
    .from(invoiceItemTable)
    .leftJoin(yarnTypeMasterTable, eq(invoiceItemTable.yarnTypeId, yarnTypeMasterTable.id))
    .leftJoin(yarnCountMasterTable, eq(invoiceItemTable.yarnCountId, yarnCountMasterTable.id))
    .where(eq(invoiceItemTable.invoiceId, id))
    .orderBy(invoiceItemTable.id);

  const transactions = await db
    .select({ transactionHeaderId: invoiceTransactionTable.transactionHeaderId })
    .from(invoiceTransactionTable)
    .where(eq(invoiceTransactionTable.invoiceId, id));

  return { ...inv, items, transactionHeaderIds: transactions.map((t) => t.transactionHeaderId) };
}

router.get("/invoicing/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid invoice id" }); return; }
  const detail = await loadInvoiceDetail(id);
  if (!detail.id) { res.status(404).json({ error: "Invoice not found" }); return; }
  res.json(detail);
});

// ─── Post invoice to FBR ──────────────────────────────────────────────────
// Manual action (draft only). Sends to sandbox or production per the config
// toggle (code 0002), using the default company's matching token. On FBR
// valid → status=posted (read-only). On invalid/transport → stays draft with
// the raw response stored for retry.

router.post("/invoicing/:id/post", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid invoice id" }); return; }

  const [inv] = await db
    .select().from(invoiceTable).where(eq(invoiceTable.id, id));
  if (!inv) { res.status(404).json({ error: "Invoice not found" }); return; }
  if (inv.status === "posted") {
    res.status(409).json({ error: "This invoice is already posted and read-only." });
    return;
  }

  const [company] = await db
    .select().from(companyInfoMasterTable).where(eq(companyInfoMasterTable.id, inv.companyId));
  if (!company) { res.status(404).json({ error: "Company not found" }); return; }

  const [party] = await db
    .select().from(partyMasterTable).where(eq(partyMasterTable.id, inv.partyId));
  if (!party) { res.status(404).json({ error: "Party not found" }); return; }

  const items = await db
    .select().from(invoiceItemTable).where(eq(invoiceItemTable.invoiceId, inv.id)).orderBy(invoiceItemTable.id);
  if (items.length === 0) {
    res.status(409).json({ error: "Invoice has no items to post." });
    return;
  }

  const sandbox = await isFbrSandboxEnabled();
  const token = sandbox ? company.fbrSandboxToken : company.fbrProductionToken;

  const payload = buildFbrInvoicePayload({
    invoice: inv,
    items,
    company,
    buyerNtnCnic: party.ntnCnic ?? null,
    buyerBusinessName: party.name,
    buyerProvince: party.province ?? "",
    buyerAddress: party.address ?? "",
    buyerRegistrationType: party.registrationType ?? "Unregistered",
    sandbox,
  });

  const result = await postInvoiceToFbr({ payload, token, sandbox });

  // FBR validation outcome.
  const vr = result.body.validationResponse;
  const valid = vr?.statusCode === "00" && vr?.status === "Valid";
  const invalid = vr && (vr.statusCode === "01" || vr.status === "Invalid");
  const fbrNumber = valid ? (result.body.invoiceNumber ?? null) : null;

  const [updated] = await db
    .update(invoiceTable)
    .set({
      fbrInvoiceNumber: fbrNumber,
      fbrStatusCode: vr?.statusCode ?? null,
      fbrRawResponse: result.raw,
      status: valid ? "posted" : "draft",
      postedAt: valid ? new Date() : null,
      updatedAt: new Date(),
    })
    .where(eq(invoiceTable.id, inv.id))
    .returning();

  if (!valid) {
    res.status(400).json({
      error: `FBR rejected the invoice${invalid ? "" : " (request failed)"}. Status: ${vr?.status ?? "error"}`,
      fbrError: vr?.error ?? null,
      fbrErrorCode: vr?.errorCode ?? null,
      invoice: updated,
    });
    return;
  }

  const detail = await loadInvoiceDetail(updated.id);
  res.json({ message: "Invoice posted to FBR", invoice: detail });
});

// ─── Delete invoice (draft only) ─────────────────────────────────────────
// Removes the invoice + its junction rows (cascade), un-marking the
// transactions so they're available for re-invoicing. Posted invoices cannot
// be deleted (handled by status guard + cascade protection in routes).

router.delete("/invoicing/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid invoice id" }); return; }

  const [inv] = await db
    .select().from(invoiceTable).where(eq(invoiceTable.id, id));
  if (!inv) { res.status(404).json({ error: "Invoice not found" }); return; }
  if (inv.status === "posted") {
    res.status(409).json({ error: "Posted invoices are read-only and cannot be deleted." });
    return;
  }

  await db.delete(invoiceTable).where(eq(invoiceTable.id, id));
  res.sendStatus(204);
});

export default router;
