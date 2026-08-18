import { Router, type IRouter } from "express";
import { eq, and, desc, inArray, sql } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  invoiceTable,
  invoiceItemTable,
  invoiceTransactionTable,
  invoicePaymentTable,
  companyInfoMasterTable,
  partyMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
  configurationTable,
} from "../db/index.js";
import {
  getUninvoicedPreview,
  listUninvoicedParties,
  getAllUninvoicedPreviews,
  computeItemAmounts,
} from "../lib/invoice-engine.js";
import {
  computePaymentState,
  toISODate,
  daysBetween,
  toNum,
} from "../lib/invoice-payments.js";
import { isFbrSandboxEnabled } from "../lib/fbr/config.js";
import { isUniqueViolation } from "../lib/db-errors.js";
import { buildFbrInvoicePayload, postInvoiceToFbr } from "../lib/fbr/client.js";
import { validateBody } from "../lib/validate.js";

const router: IRouter = Router();

/** Sales tax percent used when deriving amounts (matches the app-wide 18% FBR rate). */
const SALES_TAX_DERIVED_PERCENT = 18;

function idParam(req: { params: Record<string, unknown> }) {
  const id = parseInt(String(req.params.id ?? ""), 10);
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

router.post("/invoicing/generate", validateBody(generateBodySchema), async (req, res): Promise<void> => {
  const { partyId, createdBy, items } = req.body as unknown as z.infer<typeof generateBodySchema>;

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
    if (isUniqueViolation(err)) { conflict = true; }
    if (err && (err as { code?: string }).code === "NO_ITEMS") { conflict = true; }
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
      origin: invoiceTable.origin,
      dueDays: invoiceTable.dueDays,
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

  // Attach derived payment state per invoice (issue #189). The as-of date is
  // resolved once per request instead of once per row (each computePaymentState
  // call used to construct a fresh `new Date()`).
  const ids = rows.map((r) => r.id);
  const payments = ids.length > 0
    ? await db
        .select({
          invoiceId: invoicePaymentTable.invoiceId,
          amount: invoicePaymentTable.amount,
          taxDeduction: invoicePaymentTable.taxDeduction,
        })
        .from(invoicePaymentTable)
        .where(inArray(invoicePaymentTable.invoiceId, ids))
    : [];
  const payByInvoice = new Map<number, typeof payments>();
  for (const p of payments) {
    const arr = payByInvoice.get(p.invoiceId) ?? [];
    arr.push(p);
    payByInvoice.set(p.invoiceId, arr);
  }

  const asOfIso = toISODate(new Date());
  const out = rows.map((r) => {
    const state = computePaymentState({
      grandTotal: r.grandTotal,
      dueDays: r.dueDays,
      postedDateIso: toISODate(r.postedAt ?? new Date(r.invoiceDate)),
      payments: payByInvoice.get(r.id) ?? [],
      asOfIso,
    });
    return {
      ...r,
      dueDate: state.dueDateIso,
      paidAmount: state.paidAmount,
      outstanding: state.outstanding,
      overdue: state.overdue,
      paid: state.paid,
      overpaid: state.overpaid,
      totalTaxDeduction: state.totalTaxDeduction,
    };
  });
  res.json(out);
});


// ─── Receivables: per-party outstanding + aging ────────────────────────────
router.get("/invoicing/receivables", async (_req, res): Promise<void> => {
  const invoices = await db
    .select({
      id: invoiceTable.id,
      invoiceDate: invoiceTable.invoiceDate,
      partyId: invoiceTable.partyId,
      partyName: partyMasterTable.name,
      grandTotal: invoiceTable.grandTotal,
      dueDays: invoiceTable.dueDays,
      postedAt: invoiceTable.postedAt,
      origin: invoiceTable.origin,
    })
    .from(invoiceTable)
    .leftJoin(partyMasterTable, eq(invoiceTable.partyId, partyMasterTable.id))
    .where(eq(invoiceTable.status, "posted"));

  // Only payments against the posted invoices matter (payments can only be
  // recorded against posted invoices anyway) — filtering by the posted ids
  // lets Postgres use the invoice_payment_invoice_idx index instead of a full
  // table scan.
  const postedIds = invoices.map((i) => i.id);
  const payments = postedIds.length > 0
    ? await db
        .select({
          invoiceId: invoicePaymentTable.invoiceId,
          amount: invoicePaymentTable.amount,
          taxDeduction: invoicePaymentTable.taxDeduction,
        })
        .from(invoicePaymentTable)
        .where(inArray(invoicePaymentTable.invoiceId, postedIds))
    : [];

  const payByInvoice = new Map<number, typeof payments>();
  for (const p of payments) {
    const arr = payByInvoice.get(p.invoiceId) ?? [];
    arr.push(p);
    payByInvoice.set(p.invoiceId, arr);
  }

  const today = toISODate(new Date());
  const partyMap = new Map<number, {
    partyName: string;
    totalInvoiced: number;
    totalPaid: number;
    outstanding: number;
    totalWht: number;
    buckets: { current: number; b1_30: number; b31_60: number; b60: number };
  }>();

  for (const inv of invoices) {
    const p = payByInvoice.get(inv.id) ?? [];
    const state = computePaymentState({
      grandTotal: inv.grandTotal,
      dueDays: inv.dueDays,
      postedDateIso: toISODate(inv.postedAt ?? new Date(inv.invoiceDate ?? "")),
      payments: p,
      asOfIso: today,
    });

    const e = partyMap.get(inv.partyId) ?? {
      partyName: inv.partyName ?? `Party #${inv.partyId}`,
      totalInvoiced: 0,
      totalPaid: 0,
      outstanding: 0,
      totalWht: 0,
      buckets: { current: 0, b1_30: 0, b31_60: 0, b60: 0 },
    };
    e.totalInvoiced += toNum(inv.grandTotal);
    e.totalPaid += state.paidAmount;
    e.totalWht += state.totalTaxDeduction;

    if (state.outstanding > 0) {
      e.outstanding += state.outstanding;
      if (state.overdue && state.dueDateIso) {
        const days = daysBetween(today, state.dueDateIso);
        if (days > 60) e.buckets.b60 += state.outstanding;
        else if (days > 30) e.buckets.b31_60 += state.outstanding;
        else if (days > 0) e.buckets.b1_30 += state.outstanding;
        else e.buckets.current += state.outstanding;
      } else {
        e.buckets.current += state.outstanding;
      }
    }
    partyMap.set(inv.partyId, e);
  }

  const rows = Array.from(partyMap.entries())
    .map(([partyId, v]) => ({
      partyId,
      partyName: v.partyName,
      totalInvoiced: round2(v.totalInvoiced),
      totalPaid: round2(v.totalPaid),
      outstanding: round2(v.outstanding),
      totalTaxDeduction: round2(v.totalWht),
      aging: {
        current: round2(v.buckets.current),
        b1_30: round2(v.buckets.b1_30),
        b31_60: round2(v.buckets.b31_60),
        b60: round2(v.buckets.b60),
      },
    }))
    .sort((a, b) => a.partyName.localeCompare(b.partyName));

  res.json({ today, parties: rows });
});

function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

// ─── Latest invoice rate per (party, yarn type, yarn count) ──────────────
// Feeds the invoice-generation form's rate boxes: pre-fill with the most
// recent rate used for the same party + yarn type (+ count), while the user
// is free to override it.
router.get("/invoicing/rates/:partyId", async (req, res): Promise<void> => {
  const partyId = parseInt(req.params.partyId ?? "", 10);
  if (isNaN(partyId)) { res.status(400).json({ error: "Invalid party id" }); return; }

  const rates = await loadLatestRates(partyId);
  // Keys from loadLatestRates carry a `partyId|` prefix; strip it for the
  // single-party consumer (frontend expects `${yarnTypeId}|${yarnCountId}`).
  res.json(Array.from(rates.entries()).map(([key, v]) => ({ key: key.slice(String(partyId).length + 1), ...v })));
});

/**
 * Latest rate per (party, yarn type, yarn count): the ratePerKg of the most
 * recent invoice item for that combination, across all parties (when
 * `partyId` is undefined) or for one party. Key = `${yarnTypeId}|${yarnCountId}`.
 */
async function loadLatestRates(partyId: number | undefined): Promise<Map<string, { ratePerKg: string; invoiceDate: string; invoiceId: number }>> {
  const conditions = partyId != null ? eq(invoiceTable.partyId, partyId) : undefined;
  const rows = await db
    .selectDistinctOn(
      [invoiceTable.partyId, invoiceItemTable.yarnTypeId, invoiceItemTable.yarnCountId],
      {
        partyId: invoiceTable.partyId,
        yarnTypeId: invoiceItemTable.yarnTypeId,
        yarnCountId: invoiceItemTable.yarnCountId,
        ratePerKg: invoiceItemTable.ratePerKg,
        invoiceDate: invoiceTable.invoiceDate,
        invoiceId: invoiceTable.id,
      },
    )
    .from(invoiceItemTable)
    .innerJoin(invoiceTable, eq(invoiceItemTable.invoiceId, invoiceTable.id))
    .where(conditions)
    .orderBy(
      // DISTINCT ON (party, yt, yc) requires ORDER BY to start with exactly
      // those columns. Party is always first (constant when filtered to one).
      invoiceTable.partyId,
      invoiceItemTable.yarnTypeId,
      invoiceItemTable.yarnCountId,
      desc(invoiceTable.invoiceDate),
      desc(invoiceTable.id),
    );

  const byKey = new Map<string, { ratePerKg: string; invoiceDate: string; invoiceId: number }>();
  for (const r of rows) {
    const key = `${r.partyId}|${r.yarnTypeId}|${r.yarnCountId ?? ""}`;
    if (!byKey.has(key)) {
      byKey.set(key, { ratePerKg: r.ratePerKg, invoiceDate: r.invoiceDate, invoiceId: r.invoiceId });
    }
  }
  return byKey;
}

// ─── Future invoices: un-invoiced deliveries valued at the latest rate ────
// For every party with un-invoiced Fabric_Dispatch transactions, list each
// (party, yarn type, yarn count) group with the summed net weight and, when
// a prior invoice exists for that same combination, the latest rate and
// projected value (quantity × rate). Groups with no prior rate are returned
// with a null rate (unvalued).
router.get("/invoicing/future", async (_req, res): Promise<void> => {
  // Batch-load every party's un-invoiced preview in 2 queries instead of
  // looping per-party previews (~2N round-trips).
  const previews = await getAllUninvoicedPreviews();
  if (previews.size === 0) { res.json([]); return; }

  const rates = await loadLatestRates(undefined);
  const rows = [];

  const parties = [...previews.entries()].sort((a, b) => a[1].partyName.localeCompare(b[1].partyName));
  for (const [partyId, preview] of parties) {
    for (const g of preview.groups) {
      const rateKey = `${partyId}|${g.yarnTypeId}|${g.yarnCountId ?? ""}`;
      const rateInfo = rates.get(rateKey);
      const qty = parseFloat(g.quantity) || 0;
      const ratePerKg = rateInfo ? parseFloat(rateInfo.ratePerKg) : null;
      const value = ratePerKg != null ? qty * ratePerKg : null;
      rows.push({
        partyId,
        partyName: preview.partyName,
        yarnTypeId: g.yarnTypeId,
        yarnTypeName: g.yarnTypeName,
        yarnCountId: g.yarnCountId,
        yarnCountName: g.yarnCountName,
        hsCode: g.hsCode,
        uoM: g.uoM,
        productDescription: g.productDescription,
        quantity: g.quantity,
        ratePerKg,
        rateDate: rateInfo?.invoiceDate ?? null,
        value: value != null ? round2(value) : null,
        tax: value != null ? round2(value * SALES_TAX_DERIVED_PERCENT / 100) : null,
        total: value != null ? round2(value * (1 + SALES_TAX_DERIVED_PERCENT / 100)) : null,
      });
    }
  }

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
      companyNtnCnic: companyInfoMasterTable.ntnCnic,
      companyAddress: companyInfoMasterTable.address,
      companyProvince: companyInfoMasterTable.province,
      partyId: invoiceTable.partyId,
      partyName: partyMasterTable.name,
      partyNtnCnic: partyMasterTable.ntnCnic,
      partyAddress: partyMasterTable.address,
      partyProvince: partyMasterTable.province,
      partyRegistrationType: partyMasterTable.registrationType,
      status: invoiceTable.status,
      origin: invoiceTable.origin,
      dueDays: invoiceTable.dueDays,
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

  const payments = await loadInvoicePayments(id);

  // Posted date for due-date math: use the postedAt date when available, else
  // the invoice date (drafts have no due/overdue state but keep it safe).
  const postedIso = toISODate(inv.postedAt ?? new Date(inv.invoiceDate));
  const payState = computePaymentState({
    grandTotal: inv.grandTotal,
    dueDays: inv.dueDays,
    postedDateIso: postedIso,
    payments,
  });

  return {
    ...inv,
    items,
    transactionHeaderIds: transactions.map((t) => t.transactionHeaderId),
    payments,
    paidAmount: payState.paidAmount,
    outstanding: payState.outstanding,
    dueDate: payState.dueDateIso,
    overdue: payState.overdue,
    paid: payState.paid,
    overpaid: payState.overpaid,
    totalTaxDeduction: payState.totalTaxDeduction,
  };
}

/** Load payments for an invoice (oldest first). */
async function loadInvoicePayments(invoiceId: number) {
  return await db
    .select({
      id: invoicePaymentTable.id,
      invoiceId: invoicePaymentTable.invoiceId,
      amount: invoicePaymentTable.amount,
      taxDeduction: invoicePaymentTable.taxDeduction,
      paymentDate: invoicePaymentTable.paymentDate,
      method: invoicePaymentTable.method,
      reference: invoicePaymentTable.reference,
      notes: invoicePaymentTable.notes,
      paidBy: invoicePaymentTable.paidBy,
      createdAt: invoicePaymentTable.createdAt,
    })
    .from(invoicePaymentTable)
    .where(eq(invoicePaymentTable.invoiceId, invoiceId))
    .orderBy(invoicePaymentTable.paymentDate, invoicePaymentTable.id);
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

  // Snapshot the party's credit terms at post time (issue #189). A later edit
  // to the party's creditDays must not rewrite past invoices.
  const dueDays = (party.creditDays ?? 0) > 0 ? party.creditDays ?? 0 : null;

  // Unregistered parties are never sent to FBR: mark posted locally only.
  if ((party.registrationType ?? "Unregistered") === "Unregistered") {
    const [updated] = await db
      .update(invoiceTable)
      .set({
        status: "posted",
        origin: "local",
        dueDays,
        postedAt: new Date(),
        updatedAt: new Date(),
      })
      .where(eq(invoiceTable.id, inv.id))
      .returning();
    const detail = await loadInvoiceDetail(updated.id);
    res.json({ message: "Invoice marked posted (unregistered party — not sent to FBR)", invoice: detail });
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
      origin: "fbr",
      dueDays,
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

// ─── Config: allow backdated invoices (issue #189) ─────────────────────────
async function isAllowBackdatedInvoices(): Promise<boolean> {
  const [cfg] = await db
    .select({ enabled: configurationTable.enabled })
    .from(configurationTable)
    .where(eq(configurationTable.code, "0003"));
  return cfg?.enabled ?? false;
}

// ─── Record a payment against an invoice ───────────────────────────────────
const paymentSchema = z.object({
  amount: z.coerce.number().positive("Amount must be positive"),
  taxDeduction: z.coerce.number().min(0, "Tax deduction cannot be negative").optional().default(0),
  paymentDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Invalid date"),
  method: z.string().optional().nullable(),
  reference: z.string().optional().nullable(),
  notes: z.string().optional().nullable(),
});

router.post("/invoicing/:id/payments", validateBody(paymentSchema), async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid invoice id" }); return; }

  const [inv] = await db
    .select().from(invoiceTable).where(eq(invoiceTable.id, id));
  if (!inv) { res.status(404).json({ error: "Invoice not found" }); return; }
  if (inv.status !== "posted") {
    res.status(409).json({ error: "Payments can only be recorded against posted invoices." });
    return;
  }

  const body = req.body as unknown as z.infer<typeof paymentSchema>;
  if (body.taxDeduction > body.amount) {
    res.status(400).json({ error: "Tax deduction cannot exceed the payment amount." });
    return;
  }

  const paidBy = (req.auth?.username) ?? "system";
  const [payment] = await db
    .insert(invoicePaymentTable)
    .values({
      invoiceId: id,
      amount: body.amount.toFixed(2),
      taxDeduction: body.taxDeduction.toFixed(2),
      paymentDate: body.paymentDate,
      method: body.method || null,
      reference: body.reference || null,
      notes: body.notes || null,
      paidBy,
    })
    .returning();

  const detail = await loadInvoiceDetail(id);
  res.status(201).json({ payment, invoice: detail });
});

// ─── Delete a payment ─────────────────────────────────────────────────────
router.delete("/invoicing/:id/payments/:paymentId", async (req, res): Promise<void> => {
  const id = idParam(req);
  const paymentId = parseInt(req.params.paymentId, 10);
  if (!id || isNaN(paymentId)) { res.status(400).json({ error: "Invalid ids" }); return; }

  const [inv] = await db
    .select().from(invoiceTable).where(eq(invoiceTable.id, id));
  if (!inv) { res.status(404).json({ error: "Invoice not found" }); return; }

  const [existing] = await db
    .select().from(invoicePaymentTable).where(eq(invoicePaymentTable.id, paymentId));
  if (!existing || existing.invoiceId !== id) {
    res.status(404).json({ error: "Payment not found" });
    return;
  }

  await db.delete(invoicePaymentTable).where(eq(invoicePaymentTable.id, paymentId));
  const detail = await loadInvoiceDetail(id);
  res.json({ message: "Payment deleted", invoice: detail });
});

// ─── Backdated invoice (manual, from another system) ───────────────────────
// Only available when the "allow backdated invoices" toggle (0003) is enabled.
// Records an existing invoice: user enters the id (becomes the PK), FBR number,
// party, backdated invoice date, and line items. Standalone — no transaction
// junction, no FBR call. Created directly as posted (origin='manual').
const backdatedItemSchema = z.object({
  yarnTypeId: z.coerce.number().int().positive(),
  yarnCountId: z.coerce.number().int().positive().optional().nullable(),
  hsCode: z.string().optional().nullable(),
  uoM: z.string().optional().nullable(),
  productDescription: z.string().optional().nullable(),
  quantity: z.coerce.number().positive("Net weight must be positive"),
  ratePerKg: z.coerce.number().positive("Rate per kg must be positive"),
});

const backdatedSchema = z.object({
  id: z.coerce.number().int().positive("Manual invoice id is required"),
  partyId: z.coerce.number().int().positive("Party is required"),
  invoiceDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Invalid invoice date"),
  fbrInvoiceNumber: z.string().optional().nullable(),
  items: z.array(backdatedItemSchema).min(1, "At least one item is required"),
});

router.post("/invoicing/backdated", validateBody(backdatedSchema), async (req, res): Promise<void> => {
  if (!(await isAllowBackdatedInvoices())) {
    res.status(403).json({ error: "Backdated invoices are not enabled." });
    return;
  }

  const body = req.body as unknown as z.infer<typeof backdatedSchema>;

  // The manually-entered id becomes the actual PK — guard against existing rows
  // (the DB PK unique constraint is the backstop for races/concurrency).
  const [existing] = await db
    .select({ id: invoiceTable.id }).from(invoiceTable).where(eq(invoiceTable.id, body.id));
  if (existing) {
    res.status(400).json({ error: `An invoice with ID ${body.id} already exists.` });
    return;
  }

  const [defaultCompany] = await db
    .select().from(companyInfoMasterTable).where(eq(companyInfoMasterTable.isDefault, true));
  if (!defaultCompany) {
    res.status(409).json({ error: "No default company is configured. Set a default company in Company Info first." });
    return;
  }

  const [party] = await db
    .select().from(partyMasterTable).where(eq(partyMasterTable.id, body.partyId));
  if (!party) { res.status(404).json({ error: "Party not found" }); return; }

  const dueDays = (party.creditDays ?? 0) > 0 ? party.creditDays ?? 0 : null;
  const createdBy = (req.auth?.username) ?? "system";

  let invoice;
  try {
    await db.transaction(async (tx) => {
      let totalValue = 0;
      let totalTax = 0;
      let grandTotal = 0;
      const itemRows: (typeof invoiceItemTable.$inferInsert)[] = [];

      for (const it of body.items) {
        const amounts = computeItemAmounts(String(it.quantity), it.ratePerKg);
        totalValue += parseFloat(amounts.valueExcludingTax);
        totalTax += parseFloat(amounts.taxAmount);
        grandTotal += parseFloat(amounts.totalValue);
        itemRows.push({
          invoiceId: body.id,
          yarnTypeId: it.yarnTypeId,
          yarnCountId: it.yarnCountId ?? null,
          hsCode: it.hsCode ?? null,
          uoM: it.uoM ?? null,
          productDescription: it.productDescription ?? null,
          quantity: String(it.quantity),
          ratePerKg: String(it.ratePerKg),
          valueExcludingTax: amounts.valueExcludingTax,
          taxAmount: amounts.taxAmount,
          totalValue: amounts.totalValue,
        });
      }

      if (itemRows.length === 0) {
        throw Object.assign(new Error("No valid items"), { code: "NO_ITEMS" });
      }

      const [ins] = await tx
        .insert(invoiceTable)
        .values({
          id: body.id,
          invoiceDate: body.invoiceDate,
          companyId: defaultCompany.id,
          partyId: body.partyId,
          status: "posted",
          origin: "manual",
          dueDays,
          fbrInvoiceNumber: body.fbrInvoiceNumber || null,
          totalValue: totalValue.toFixed(2),
          totalTax: totalTax.toFixed(2),
          grandTotal: grandTotal.toFixed(2),
          createdBy,
          postedAt: new Date(body.invoiceDate + "T00:00:00"),
        })
        .returning();

      await tx.insert(invoiceItemTable).values(itemRows);
      invoice = ins;
    });
  } catch (err) {
    if (isUniqueViolation(err)) {
      res.status(400).json({ error: `An invoice with ID ${body.id} already exists.` });
      return;
    }
    if ((err as { code?: string }).code === "NO_ITEMS") {
      res.status(400).json({ error: "No valid items were provided." });
      return;
    }
    throw err;
  }

  const detail = await loadInvoiceDetail(invoice!.id);
  res.status(201).json({ message: "Backdated invoice created", invoice: detail });
});

export default router;
