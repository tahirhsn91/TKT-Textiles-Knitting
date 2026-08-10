import { Router, type IRouter } from "express";
import { eq, and, gte, lte, sql } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  dailyDeliveryTable,
  partyMasterTable,
  yarnTypeMasterTable,
  insertDailyDeliverySchema,
} from "../db/index.js";
import { isReconciliationLockEnabled } from "../lib/reconciliation-lock.js";
import { retrainAfterInsert } from "../lib/plausibility/engine.js";

const router: IRouter = Router();

// ─── Validation ────────────────────────────────────────────────────────────

const deliverySchema = insertDailyDeliverySchema.extend({
  deliveryDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Delivery date (YYYY-MM-DD) is required"),
  partyId: z.coerce.number().int().positive("Party is required"),
  yarnTypeId: z.coerce.number().int().positive("Yarn type is required"),
  challanNo: z.string().min(1, "Challan # is required"),
  sl: z.string().optional().nullable(),
  gsm: z.coerce.number().int().positive("GSM must be a positive number").optional().nullable(),
  quantity: z.coerce.number().int().positive("Quantity must be a whole number greater than zero"),
  netWeight: z.coerce.number().positive("Net weight must be greater than zero"),
  createdBy: z.string().min(1, "Enter your name"),
  updatedBy: z.string().optional(),
});

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

/**
 * Guard for deliveries already booked into a Fabric Delivery transaction.
 * Returns a 409 payload when locked, or null when free. Mirrors the
 * reconciliationBlock in daily-production / yarn-receipts, gated on the
 * Reconciliation lock config (0001): when it's disabled, booked deliveries
 * stay editable.
 */
async function reconciliationBlock(
  id: number,
): Promise<{ error: string; reconciledTransactionId: number | null } | null> {
  if (!(await isReconciliationLockEnabled())) return null;

  const [row] = await db
    .select({
      reconciled: dailyDeliveryTable.reconciled,
      reconciledTransactionId: dailyDeliveryTable.reconciledTransactionId,
    })
    .from(dailyDeliveryTable)
    .where(eq(dailyDeliveryTable.id, id));

  if (!row || !row.reconciled) return null;

  return {
    error:
      "This delivery has been booked into a Fabric Delivery transaction and can no longer be changed.",
    reconciledTransactionId: row.reconciledTransactionId,
  };
}

// ─── List deliveries for a date (summary, one row per delivery) ────────────

router.get("/daily-deliveries", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" && req.query.date ? req.query.date : todayIso();

  const rows = await db
    .select({
      id: dailyDeliveryTable.id,
      deliveryDate: dailyDeliveryTable.deliveryDate,
      partyId: dailyDeliveryTable.partyId,
      partyName: partyMasterTable.name,
      yarnTypeId: dailyDeliveryTable.yarnTypeId,
      yarnTypeName: yarnTypeMasterTable.name,
      challanNo: dailyDeliveryTable.challanNo,
      sl: dailyDeliveryTable.sl,
      gsm: dailyDeliveryTable.gsm,
      quantity: dailyDeliveryTable.quantity,
      netWeight: dailyDeliveryTable.netWeight,
      createdBy: dailyDeliveryTable.createdBy,
      reconciled: dailyDeliveryTable.reconciled,
      reconciledTransactionId: dailyDeliveryTable.reconciledTransactionId,
    })
    .from(dailyDeliveryTable)
    .leftJoin(partyMasterTable, eq(dailyDeliveryTable.partyId, partyMasterTable.id))
    .leftJoin(yarnTypeMasterTable, eq(dailyDeliveryTable.yarnTypeId, yarnTypeMasterTable.id))
    .where(and(
      eq(dailyDeliveryTable.deliveryDate, date),
      eq(dailyDeliveryTable.status, "submitted"),
    ))
    .orderBy(dailyDeliveryTable.id);

  // Month-to-date totals — same shape as the yarn receipt / production summaries.
  const monthStart = `${date.slice(0, 7)}-01`;
  const [monthToDate] = await db
    .select({
      totalQty: sql<number>`coalesce(sum(${dailyDeliveryTable.quantity}), 0)::int`,
      totalNetWeight: sql<string>`coalesce(sum(${dailyDeliveryTable.netWeight}), 0)`,
    })
    .from(dailyDeliveryTable)
    .where(and(
      gte(dailyDeliveryTable.deliveryDate, monthStart),
      lte(dailyDeliveryTable.deliveryDate, date),
      eq(dailyDeliveryTable.status, "submitted"),
    ));

  // Per-day series from the 1st of the month through the selected date, for
  // the month-trend chart. Frontend fills any gaps.
  const monthSeries = await db
    .select({
      date: dailyDeliveryTable.deliveryDate,
      totalQty: sql<number>`coalesce(sum(${dailyDeliveryTable.quantity}), 0)::int`,
      totalNetWeight: sql<string>`coalesce(sum(${dailyDeliveryTable.netWeight}), 0)`,
    })
    .from(dailyDeliveryTable)
    .where(and(
      gte(dailyDeliveryTable.deliveryDate, monthStart),
      lte(dailyDeliveryTable.deliveryDate, date),
      eq(dailyDeliveryTable.status, "submitted"),
    ))
    .groupBy(dailyDeliveryTable.deliveryDate)
    .orderBy(dailyDeliveryTable.deliveryDate);

  res.json({
    deliveryDate: date,
    rows,
    monthToDate: {
      totalQty: monthToDate?.totalQty ?? 0,
      totalNetWeight: monthToDate?.totalNetWeight ?? "0",
    },
    monthSeries,
  });
});

// ─── Next challan number suggestion ────────────────────────────────────────
// Smallest unused integer-based challan number (e.g. "D-1", "D-2"…). Kept
// numeric so it sorts naturally on the delivery sheet.

router.get("/daily-deliveries/suggestions", async (_req, res): Promise<void> => {
  const rows = await db
    .select({ challanNo: dailyDeliveryTable.challanNo })
    .from(dailyDeliveryTable)
    .orderBy(dailyDeliveryTable.id);

  let maxNumeric = 0;
  for (const r of rows) {
    const n = parseInt((r.challanNo ?? "").replace(/^D-\s*/i, ""), 10);
    if (!isNaN(n) && n > maxNumeric) maxNumeric = n;
  }

  res.json({ nextChallanNo: `D-${maxNumeric + 1}` });
});

// ─── Unreconciled deliveries for a date + party ───────────────────────────
// Feeds the New Transaction screen when the type is Fabric Delivery. Only
// returns deliveries not yet consumed by another transaction, so the same
// delivery can never be booked twice.
//
// MUST stay above "/daily-deliveries/:id" — Express matches in order.

router.get("/daily-deliveries/unreconciled", async (req, res): Promise<void> => {
  const date = typeof req.query.date === "string" ? req.query.date : "";
  const partyId = parseInt(String(req.query.partyId ?? ""), 10);

  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || isNaN(partyId)) {
    res.status(400).json({ error: "date (YYYY-MM-DD) and partyId are required" });
    return;
  }

  const rows = await db
    .select({
      id: dailyDeliveryTable.id,
      deliveryDate: dailyDeliveryTable.deliveryDate,
      partyId: dailyDeliveryTable.partyId,
      partyName: partyMasterTable.name,
      yarnTypeId: dailyDeliveryTable.yarnTypeId,
      yarnTypeName: yarnTypeMasterTable.name,
      challanNo: dailyDeliveryTable.challanNo,
      sl: dailyDeliveryTable.sl,
      gsm: dailyDeliveryTable.gsm,
      quantity: dailyDeliveryTable.quantity,
      netWeight: dailyDeliveryTable.netWeight,
    })
    .from(dailyDeliveryTable)
    .leftJoin(partyMasterTable, eq(dailyDeliveryTable.partyId, partyMasterTable.id))
    .leftJoin(yarnTypeMasterTable, eq(dailyDeliveryTable.yarnTypeId, yarnTypeMasterTable.id))
    .where(and(
      eq(dailyDeliveryTable.deliveryDate, date),
      eq(dailyDeliveryTable.partyId, partyId),
      eq(dailyDeliveryTable.status, "submitted"),
      eq(dailyDeliveryTable.reconciled, false),
    ))
    .orderBy(dailyDeliveryTable.id);

  res.json({ deliveryDate: date, partyId, rows });
});

// ─── Delivery detail ───────────────────────────────────────────────────────

router.get("/daily-deliveries/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid delivery id" });
    return;
  }

  const [row] = await db
    .select({
      id: dailyDeliveryTable.id,
      deliveryDate: dailyDeliveryTable.deliveryDate,
      partyId: dailyDeliveryTable.partyId,
      partyName: partyMasterTable.name,
      yarnTypeId: dailyDeliveryTable.yarnTypeId,
      yarnTypeName: yarnTypeMasterTable.name,
      challanNo: dailyDeliveryTable.challanNo,
      sl: dailyDeliveryTable.sl,
      gsm: dailyDeliveryTable.gsm,
      quantity: dailyDeliveryTable.quantity,
      netWeight: dailyDeliveryTable.netWeight,
      createdBy: dailyDeliveryTable.createdBy,
      updatedBy: dailyDeliveryTable.updatedBy,
      createdAt: dailyDeliveryTable.createdAt,
      updatedAt: dailyDeliveryTable.updatedAt,
    })
    .from(dailyDeliveryTable)
    .leftJoin(partyMasterTable, eq(dailyDeliveryTable.partyId, partyMasterTable.id))
    .leftJoin(yarnTypeMasterTable, eq(dailyDeliveryTable.yarnTypeId, yarnTypeMasterTable.id))
    .where(eq(dailyDeliveryTable.id, id));

  if (!row) {
    res.status(404).json({ error: "Delivery not found" });
    return;
  }
  res.json(row);
});

// ─── Create ────────────────────────────────────────────────────────────────

router.post("/daily-deliveries", async (req, res): Promise<void> => {
  const parsed = deliverySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid delivery" });
    return;
  }
  const { deliveryDate, partyId, yarnTypeId, challanNo, sl, gsm, quantity, netWeight, createdBy } = parsed.data;

  const [row] = await db
    .insert(dailyDeliveryTable)
    .values({
      deliveryDate,
      partyId,
      yarnTypeId,
      challanNo,
      sl: sl ?? null,
      gsm: gsm ?? null,
      quantity,
      netWeight: String(netWeight),
      createdBy,
    })
    .returning({ id: dailyDeliveryTable.id });

  // Self-tuning: fold the new delivery into the learned baseline. Non-fatal.
  await retrainAfterInsert("delivery");

  res.status(201).json({ id: row.id });
});

// ─── Update ────────────────────────────────────────────────────────────────

router.put("/daily-deliveries/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid delivery id" });
    return;
  }

  const parsed = deliverySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid delivery" });
    return;
  }
  const { deliveryDate, partyId, yarnTypeId, challanNo, sl, gsm, quantity, netWeight, createdBy, updatedBy } = parsed.data;

  const blocked = await reconciliationBlock(id);
  if (blocked) { res.status(409).json(blocked); return; }

  const [row] = await db
    .update(dailyDeliveryTable)
    .set({
      deliveryDate,
      partyId,
      yarnTypeId,
      challanNo,
      sl: sl ?? null,
      gsm: gsm ?? null,
      quantity,
      netWeight: String(netWeight),
      updatedBy: updatedBy ?? createdBy,
      updatedAt: new Date(),
    })
    .where(eq(dailyDeliveryTable.id, id))
    .returning({ id: dailyDeliveryTable.id });

  if (!row) {
    res.status(404).json({ error: "Delivery not found" });
    return;
  }
  res.json({ id });
});

// ─── Delete ────────────────────────────────────────────────────────────────

router.delete("/daily-deliveries/:id", async (req, res): Promise<void> => {
  const id = parseInt(req.params.id, 10);
  if (isNaN(id)) {
    res.status(400).json({ error: "Invalid delivery id" });
    return;
  }

  const blocked = await reconciliationBlock(id);
  if (blocked) { res.status(409).json(blocked); return; }

  const [row] = await db
    .delete(dailyDeliveryTable)
    .where(eq(dailyDeliveryTable.id, id))
    .returning({ id: dailyDeliveryTable.id });

  if (!row) {
    res.status(404).json({ error: "Delivery not found" });
    return;
  }
  res.status(204).end();
});

export default router;
