import { Router, type IRouter } from "express";
import { eq, and, gte, lte, sql, desc } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  yarnReceiptHeaderTable,
  yarnReceiptDetailTable,
  partyMasterTable,
  yarnCountMasterTable,
  yarnBrandMasterTable,
  insertYarnReceiptHeaderSchema,
  insertYarnReceiptDetailSchema,
} from "../db/index.js";

const router: IRouter = Router();

// ─── Validation ────────────────────────────────────────────────────────────

const headerSchema = insertYarnReceiptHeaderSchema.extend({
  docNumber: z.string().min(1, "Document number is required"),
  partyId: z.coerce.number().int().positive("Party is required"),
  createdBy: z.string().min(1, "Enter your name"),
});

const detailSchema = insertYarnReceiptDetailSchema.extend({
  yarnCountId: z.coerce.number().int().positive("Yarn count is required"),
  yarnBrandId: z.coerce.number().int().positive("Yarn brand is required"),
  quantity: z.coerce.number().int().positive("Quantity must be a whole number greater than zero"),
  netWeight: z.coerce.number().positive("Net weight must be greater than zero"),
});

const receiptBodySchema = z.object({
  docNumber: headerSchema.shape.docNumber,
  receiptDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Receipt date (YYYY-MM-DD) is required"),
  partyId: headerSchema.shape.partyId,
  createdBy: headerSchema.shape.createdBy,
  updatedBy: z.string().optional(),
  lines: z.array(detailSchema).min(1, "At least one yarn line is required"),
});

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Guard for receipts already consumed by a Yarn Receipt transaction.
 * Returns a 409 payload when the receipt is locked, or null when free.
 * Mirrors daily-production's reconciliationBlock.
 */
async function reconciliationBlock(
  id: number,
): Promise<{ error: string; reconciledTransactionId: number | null } | null> {
  const [row] = await db
    .select({
      reconciled: yarnReceiptHeaderTable.reconciled,
      reconciledTransactionId: yarnReceiptHeaderTable.reconciledTransactionId,
    })
    .from(yarnReceiptHeaderTable)
    .where(eq(yarnReceiptHeaderTable.id, id));

  if (!row || !row.reconciled) return null;

  return {
    error:
      "This receipt has been booked into a Yarn Receipt transaction and can no longer be changed.",
    reconciledTransactionId: row.reconciledTransactionId,
  };
}

// ─── List receipts for a date (summary, one row per header) ───────────────

router.get("/yarn-receipts", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" && req.query.date ? req.query.date : todayIso();

  const rows = await db
    .select({
      id: yarnReceiptHeaderTable.id,
      docNumber: yarnReceiptHeaderTable.docNumber,
      receiptDate: yarnReceiptHeaderTable.receiptDate,
      partyId: yarnReceiptHeaderTable.partyId,
      partyName: partyMasterTable.name,
      createdBy: yarnReceiptHeaderTable.createdBy,
      reconciled: yarnReceiptHeaderTable.reconciled,
      reconciledTransactionId: yarnReceiptHeaderTable.reconciledTransactionId,
      lineCount: sql<number>`count(${yarnReceiptDetailTable.id})::int`,
      totalQty: sql<number>`coalesce(sum(${yarnReceiptDetailTable.quantity}), 0)::int`,
      totalNetWeight: sql<string>`coalesce(sum(${yarnReceiptDetailTable.netWeight}), 0)`,
    })
    .from(yarnReceiptHeaderTable)
    .leftJoin(yarnReceiptDetailTable, eq(yarnReceiptDetailTable.headerId, yarnReceiptHeaderTable.id))
    .leftJoin(partyMasterTable, eq(yarnReceiptHeaderTable.partyId, partyMasterTable.id))
    .where(and(
      eq(yarnReceiptHeaderTable.receiptDate, date),
      eq(yarnReceiptHeaderTable.status, "submitted"),
    ))
    .groupBy(
      yarnReceiptHeaderTable.id,
      partyMasterTable.name,
    )
    .orderBy(yarnReceiptHeaderTable.id);

  // Month-to-date totals — same shape as the daily production summary.
  const monthStart = `${date.slice(0, 7)}-01`;
  const [monthToDate] = await db
    .select({
      totalQty: sql<number>`coalesce(sum(${yarnReceiptDetailTable.quantity}), 0)::int`,
      totalNetWeight: sql<string>`coalesce(sum(${yarnReceiptDetailTable.netWeight}), 0)`,
    })
    .from(yarnReceiptHeaderTable)
    .leftJoin(yarnReceiptDetailTable, eq(yarnReceiptDetailTable.headerId, yarnReceiptHeaderTable.id))
    .where(and(
      gte(yarnReceiptHeaderTable.receiptDate, monthStart),
      lte(yarnReceiptHeaderTable.receiptDate, date),
      eq(yarnReceiptHeaderTable.status, "submitted"),
    ));

  res.json({
    receiptDate: date,
    rows,
    monthToDate: {
      totalQty: monthToDate?.totalQty ?? 0,
      totalNetWeight: monthToDate?.totalNetWeight ?? "0",
    },
  });
});

// ─── Analytics for the Yarn Receipts screen ────────────────────────────────
// Two payloads in one call: every receipt line for the selected date (with
// count/brand/party names for the day charts) and a per-day series for the
// current month up to the selected date (for the month-trend chart).
//
// MUST stay above "/yarn-receipts/:id" — same route-order rule as
// "unreconciled".

router.get("/yarn-receipts/analytics", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" && req.query.date ? req.query.date : todayIso();

  const lines = await db
    .select({
      lineId: yarnReceiptDetailTable.id,
      receiptId: yarnReceiptHeaderTable.id,
      partyName: partyMasterTable.name,
      yarnCountId: yarnReceiptDetailTable.yarnCountId,
      yarnCountName: yarnCountMasterTable.count,
      yarnBrandId: yarnReceiptDetailTable.yarnBrandId,
      yarnBrandName: yarnBrandMasterTable.name,
      quantity: yarnReceiptDetailTable.quantity,
      netWeight: yarnReceiptDetailTable.netWeight,
    })
    .from(yarnReceiptHeaderTable)
    .leftJoin(yarnReceiptDetailTable, eq(yarnReceiptDetailTable.headerId, yarnReceiptHeaderTable.id))
    .leftJoin(partyMasterTable, eq(yarnReceiptHeaderTable.partyId, partyMasterTable.id))
    .leftJoin(yarnCountMasterTable, eq(yarnReceiptDetailTable.yarnCountId, yarnCountMasterTable.id))
    .leftJoin(yarnBrandMasterTable, eq(yarnReceiptDetailTable.yarnBrandId, yarnBrandMasterTable.id))
    .where(and(
      eq(yarnReceiptHeaderTable.receiptDate, date),
      eq(yarnReceiptHeaderTable.status, "submitted"),
    ))
    .orderBy(yarnReceiptDetailTable.id);

  // Per-day totals from the 1st of the month through the selected date.
  // The frontend fills any gaps (days with no receipts) to draw a full axis.
  const monthStart = `${date.slice(0, 7)}-01`;
  const monthSeries = await db
    .select({
      date: yarnReceiptHeaderTable.receiptDate,
      totalQty: sql<number>`coalesce(sum(${yarnReceiptDetailTable.quantity}), 0)::int`,
      totalNetWeight: sql<string>`coalesce(sum(${yarnReceiptDetailTable.netWeight}), 0)`,
    })
    .from(yarnReceiptHeaderTable)
    .leftJoin(yarnReceiptDetailTable, eq(yarnReceiptDetailTable.headerId, yarnReceiptHeaderTable.id))
    .where(and(
      gte(yarnReceiptHeaderTable.receiptDate, monthStart),
      lte(yarnReceiptHeaderTable.receiptDate, date),
      eq(yarnReceiptHeaderTable.status, "submitted"),
    ))
    .groupBy(yarnReceiptHeaderTable.receiptDate)
    .orderBy(yarnReceiptHeaderTable.receiptDate);

  res.json({ receiptDate: date, lines, monthSeries });
});

// ─── Unreconciled receipts for a date + party ─────────────────────────────
// Feeds the New Transaction screen when the type is Yarn Receipt. Only
// returns receipts not yet consumed by another transaction, so the same
// receipt can never be booked twice.
//
// MUST stay above "/yarn-receipts/:id" — Express matches in order, and
// "unreconciled" would otherwise be parsed as an id.

router.get("/yarn-receipts/unreconciled", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" ? req.query.date : "";
  const partyId = parseInt(String(req.query.partyId ?? ""), 10);

  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || isNaN(partyId)) {
    res.status(400).json({ error: "date (YYYY-MM-DD) and partyId are required" });
    return;
  }

  const rows = await db
    .select({
      id: yarnReceiptHeaderTable.id,
      receiptDate: yarnReceiptHeaderTable.receiptDate,
      partyId: yarnReceiptHeaderTable.partyId,
      partyName: partyMasterTable.name,
      lineId: yarnReceiptDetailTable.id,
      yarnCountId: yarnReceiptDetailTable.yarnCountId,
      yarnCountName: yarnCountMasterTable.count,
      yarnBrandId: yarnReceiptDetailTable.yarnBrandId,
      yarnBrandName: yarnBrandMasterTable.name,
      quantity: yarnReceiptDetailTable.quantity,
      netWeight: yarnReceiptDetailTable.netWeight,
    })
    .from(yarnReceiptHeaderTable)
    .leftJoin(yarnReceiptDetailTable, eq(yarnReceiptDetailTable.headerId, yarnReceiptHeaderTable.id))
    .leftJoin(partyMasterTable, eq(yarnReceiptHeaderTable.partyId, partyMasterTable.id))
    .leftJoin(yarnCountMasterTable, eq(yarnReceiptDetailTable.yarnCountId, yarnCountMasterTable.id))
    .leftJoin(yarnBrandMasterTable, eq(yarnReceiptDetailTable.yarnBrandId, yarnBrandMasterTable.id))
    .where(and(
      eq(yarnReceiptHeaderTable.receiptDate, date),
      eq(yarnReceiptHeaderTable.partyId, partyId),
      eq(yarnReceiptHeaderTable.status, "submitted"),
      eq(yarnReceiptHeaderTable.reconciled, false),
    ))
    .orderBy(yarnReceiptHeaderTable.id, yarnReceiptDetailTable.id);

  // One transaction line per receipt *line*; the receipt ids to claim on save
  // are the distinct header ids. Dedupe happens client-side — a receipt with
  // several lines must be claimed once, not once per line.
  const receiptIds = [...new Set(rows.map((r) => r.id))];

  res.json({ receiptDate: date, partyId, rows, receiptIds });
});

// ─── Next document number suggestion ───────────────────────────────────────
// Smallest unused integer-based doc number — same convention as
// /transactions/suggestions, so receipt docs stay human-friendly (YR-1, YR-2…).

router.get("/yarn-receipts/suggestions", async (_req, res): Promise<void> => {
  const rows = await db
    .select({ docNumber: yarnReceiptHeaderTable.docNumber })
    .from(yarnReceiptHeaderTable)
    .orderBy(desc(yarnReceiptHeaderTable.id));

  // Doc numbers look like "YR-5"; extract the numeric tail so the next
  // suggestion is YR-6, not a re-suggested 1.
  let maxNumeric = 0;
  for (const r of rows) {
    const n = parseInt((r.docNumber ?? "").replace(/^YR-\s*/i, ""), 10);
    if (!isNaN(n) && n > maxNumeric) maxNumeric = n;
  }

  res.json({ nextDocNumber: `YR-${maxNumeric + 1}` });
});

// ─── Receipt detail (header + lines) ───────────────────────────────────────

router.get("/yarn-receipts/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid receipt id" });
    return;
  }

  const [header] = await db
    .select({
      id: yarnReceiptHeaderTable.id,
      docNumber: yarnReceiptHeaderTable.docNumber,
      receiptDate: yarnReceiptHeaderTable.receiptDate,
      partyId: yarnReceiptHeaderTable.partyId,
      partyName: partyMasterTable.name,
      createdBy: yarnReceiptHeaderTable.createdBy,
      updatedBy: yarnReceiptHeaderTable.updatedBy,
      createdAt: yarnReceiptHeaderTable.createdAt,
      updatedAt: yarnReceiptHeaderTable.updatedAt,
    })
    .from(yarnReceiptHeaderTable)
    .leftJoin(partyMasterTable, eq(yarnReceiptHeaderTable.partyId, partyMasterTable.id))
    .where(eq(yarnReceiptHeaderTable.id, id));

  if (!header) {
    res.status(404).json({ error: "Receipt not found" });
    return;
  }

  const lines = await db
    .select({
      id: yarnReceiptDetailTable.id,
      yarnCountId: yarnReceiptDetailTable.yarnCountId,
      yarnCountName: yarnCountMasterTable.count,
      yarnBrandId: yarnReceiptDetailTable.yarnBrandId,
      yarnBrandName: yarnBrandMasterTable.name,
      quantity: yarnReceiptDetailTable.quantity,
      netWeight: yarnReceiptDetailTable.netWeight,
    })
    .from(yarnReceiptDetailTable)
    .leftJoin(yarnCountMasterTable, eq(yarnReceiptDetailTable.yarnCountId, yarnCountMasterTable.id))
    .leftJoin(yarnBrandMasterTable, eq(yarnReceiptDetailTable.yarnBrandId, yarnBrandMasterTable.id))
    .where(eq(yarnReceiptDetailTable.headerId, id))
    .orderBy(yarnReceiptDetailTable.id);

  res.json({ ...header, lines });
});

// ─── Create ────────────────────────────────────────────────────────────────

router.post("/yarn-receipts", async (req, res): Promise<void> => {
  const parsed = receiptBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid receipt" });
    return;
  }
  const { docNumber, receiptDate, partyId, createdBy, lines } = parsed.data;

  const result = await db.transaction(async (tx) => {
    const [header] = await tx
      .insert(yarnReceiptHeaderTable)
      .values({ docNumber, receiptDate, partyId, createdBy })
      .returning({ id: yarnReceiptHeaderTable.id });
    await tx.insert(yarnReceiptDetailTable).values(
      lines.map((l) => ({
        headerId: header.id,
        yarnCountId: l.yarnCountId,
        yarnBrandId: l.yarnBrandId,
        quantity: l.quantity,
        netWeight: String(l.netWeight),
      })),
    );
    return header;
  });

  res.status(201).json({ id: result.id });
});

// ─── Update (replace header + lines wholesale) ─────────────────────────────

router.put("/yarn-receipts/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid receipt id" });
    return;
  }

  const parsed = receiptBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid receipt" });
    return;
  }
  const { docNumber, receiptDate, partyId, createdBy, updatedBy, lines } = parsed.data;

  const [existing] = await db
    .select({ id: yarnReceiptHeaderTable.id })
    .from(yarnReceiptHeaderTable)
    .where(eq(yarnReceiptHeaderTable.id, id));
  if (!existing) {
    res.status(404).json({ error: "Receipt not found" });
    return;
  }

  const blocked = await reconciliationBlock(id);
  if (blocked) { res.status(409).json(blocked); return; }

  await db.transaction(async (tx) => {
    await tx
      .update(yarnReceiptHeaderTable)
      .set({ docNumber, receiptDate, partyId, updatedBy: updatedBy ?? createdBy, updatedAt: new Date() })
      .where(eq(yarnReceiptHeaderTable.id, id));
    await tx.delete(yarnReceiptDetailTable).where(eq(yarnReceiptDetailTable.headerId, id));
    await tx.insert(yarnReceiptDetailTable).values(
      lines.map((l) => ({
        headerId: id,
        yarnCountId: l.yarnCountId,
        yarnBrandId: l.yarnBrandId,
        quantity: l.quantity,
        netWeight: String(l.netWeight),
      })),
    );
  });

  res.json({ id });
});

// ─── Delete ────────────────────────────────────────────────────────────────

router.delete("/yarn-receipts/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid receipt id" });
    return;
  }

  const blocked = await reconciliationBlock(id);
  if (blocked) { res.status(409).json(blocked); return; }

  const result = await db
    .delete(yarnReceiptHeaderTable)
    .where(eq(yarnReceiptHeaderTable.id, id))
    .returning({ id: yarnReceiptHeaderTable.id });

  if (result.length === 0) {
    res.status(404).json({ error: "Receipt not found" });
    return;
  }
  res.json({ id });
});

export default router;
