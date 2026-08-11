import { Router, type IRouter } from "express";
import { eq, and, gte, lte, inArray, sql } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  transactionTypeMasterTable,
  transactionHeaderTable,
  transactionDetailTable,
  partyMasterTable,
  fabricTypeMasterTable,
} from "../db/index.js";

const router: IRouter = Router();

const FABRIC_PRODUCTION_CODE = "Fabric_Production";
const FABRIC_DELIVERY_CODE = "Fabric_Dispatch";

const MONTHS = [
  "01","02","03","04","05","06","07","08","09","10","11","12",
];

function toNum(v: unknown): number {
  const n = typeof v === "string" ? parseFloat(v) : Number(v ?? 0);
  return Number.isFinite(n) ? n : 0;
}

/** Last day of a month (handles leap years). */
function lastDayOfMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate(); // month is 1-based; day 0 = last of prev
}

/** Resolve the transaction type ids for the two fabric flows. */
async function resolveFabricTypeIds(): Promise<{ productionId: number; deliveryId: number } | null> {
  const [production, delivery] = await Promise.all([
    db
      .select({ id: transactionTypeMasterTable.id })
      .from(transactionTypeMasterTable)
      .where(eq(transactionTypeMasterTable.code, FABRIC_PRODUCTION_CODE)),
    db
      .select({ id: transactionTypeMasterTable.id })
      .from(transactionTypeMasterTable)
      .where(eq(transactionTypeMasterTable.code, FABRIC_DELIVERY_CODE)),
  ]);
  const productionId = production[0]?.id;
  const deliveryId = delivery[0]?.id;
  if (!productionId || !deliveryId) return null;
  return { productionId, deliveryId };
}

const partySchema = z.object({
  month: z.preprocess((v) => Number(v), z.number().int().min(1).max(12)),
  year: z.preprocess((v) => Number(v), z.number().int().min(2000).max(2100)),
  partyId: z.preprocess((v) => (v === undefined || v === "" || v === null ? undefined : Number(v)), z.number().int().positive().optional()),
});

/**
 * GET /api/party-analytics?month=&year=&partyId=
 *
 * Fabric Production vs Fabric Delivery analytics for a party + month + year.
 * - Past months: full month (1st -> last day).
 * - Current month: 1st -> today (future days excluded).
 * - partyId omitted/null: by-party breakdown across all parties.
 * - partyId set: single-party totals + fabric breakdown + daily trend.
 *
 * Only Fabric Production + Fabric Delivery types are counted. Roll (quantity)
 * and net weight (kg) come from transaction_detail rows.
 */
router.get("/party-analytics", async (req, res): Promise<void> => {
  const parsed = partySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0]?.message ?? "Invalid filters" });
    return;
  }
  const { month, year, partyId } = parsed.data;

  const now = new Date();
  const nowYear = now.getFullYear();
  const nowMonth = now.getMonth() + 1; // 1-based
  const today = now.getDate();

  const isCurrentMonth = year === nowYear && month === nowMonth;
  const from = `${year}-${MONTHS[month - 1]}-01`;
  // Current month: bound to today; past months: full month.
  const dayTo = isCurrentMonth ? today : lastDayOfMonth(year, month);
  const to = `${year}-${MONTHS[month - 1]}-${String(dayTo).padStart(2, "0")}`;

  const typeIds = await resolveFabricTypeIds();
  if (!typeIds) {
    res.status(500).json({ error: "Fabric Production / Delivery transaction types are not configured" });
    return;
  }
  const { productionId, deliveryId } = typeIds;

  // ── Header-level filters shared by every aggregate ────────────────────
  // Apply the party filter here so a single-party view only sums that party's
  // rows (totals / fabric breakdown / daily trend all inherit this scope).
  const headerWhere = and(
    inArray(transactionHeaderTable.transactionTypeId, [productionId, deliveryId]),
    gte(transactionHeaderTable.date, from),
    lte(transactionHeaderTable.date, to),
    partyId != null ? eq(transactionHeaderTable.partyId, partyId) : undefined,
  );

  // Resolve the selected party (if any).
  let party = null;
  if (partyId != null) {
    const [p] = await db
      .select()
      .from(partyMasterTable)
      .where(eq(partyMasterTable.id, partyId));
    party = p
      ? { id: p.id, name: p.name, code: p.code }
      : null;
    if (!party) {
      res.status(404).json({ error: "Party not found" });
      return;
    }
  }

  // ── Aggregate per (type, party, fabric type, date) ─────────────────────
  // One scan of the relevant detail rows; every section is derived from it.
  const rows = await db
    .select({
      transactionTypeId: transactionHeaderTable.transactionTypeId,
      partyId: transactionHeaderTable.partyId,
      partyName: partyMasterTable.name,
      fabricTypeId: transactionHeaderTable.fabricTypeId,
      fabricTypeName: fabricTypeMasterTable.name,
      date: transactionHeaderTable.date,
      kg: sql<string>`coalesce(sum(${transactionDetailTable.netWt}), 0)`,
      rolls: sql<string>`coalesce(sum(${transactionDetailTable.quantity}), 0)`,
    })
    .from(transactionDetailTable)
    .innerJoin(
      transactionHeaderTable,
      eq(transactionDetailTable.headerId, transactionHeaderTable.id),
    )
    .leftJoin(partyMasterTable, eq(transactionHeaderTable.partyId, partyMasterTable.id))
    .leftJoin(fabricTypeMasterTable, eq(transactionHeaderTable.fabricTypeId, fabricTypeMasterTable.id))
    .where(headerWhere)
    .groupBy(
      transactionHeaderTable.transactionTypeId,
      transactionHeaderTable.partyId,
      partyMasterTable.name,
      transactionHeaderTable.fabricTypeId,
      fabricTypeMasterTable.name,
      transactionHeaderTable.date,
    );

  // ── Totals (aggregate over selected scope) ─────────────────────────────
  let productionKg = 0, productionRolls = 0, deliveryKg = 0, deliveryRolls = 0;
  for (const r of rows) {
    const kg = toNum(r.kg);
    const rolls = toNum(r.rolls);
    if (r.transactionTypeId === productionId) {
      productionKg += kg;
      productionRolls += rolls;
    } else if (r.transactionTypeId === deliveryId) {
      deliveryKg += kg;
      deliveryRolls += rolls;
    }
  }

  // ── By-party breakdown (only when partyId is null) ─────────────────────
  const partyMap = new Map<number, { partyId: number; partyName: string; productionKg: number; productionRolls: number; deliveryKg: number; deliveryRolls: number }>();
  const byParty = [];
  if (partyId == null) {
    for (const r of rows) {
      if (r.partyId == null) continue;
      let entry = partyMap.get(r.partyId);
      if (!entry) {
        entry = { partyId: r.partyId, partyName: r.partyName ?? `Party ${r.partyId}`, productionKg: 0, productionRolls: 0, deliveryKg: 0, deliveryRolls: 0 };
        partyMap.set(r.partyId, entry);
      }
      const kg = toNum(r.kg);
      const rolls = toNum(r.rolls);
      if (r.transactionTypeId === productionId) { entry.productionKg += kg; entry.productionRolls += rolls; }
      else if (r.transactionTypeId === deliveryId) { entry.deliveryKg += kg; entry.deliveryRolls += rolls; }
    }
    for (const e of partyMap.values()) {
      byParty.push({
        partyId: e.partyId,
        partyName: e.partyName,
        production: { kg: round2(e.productionKg), rolls: round2(e.productionRolls) },
        delivery: { kg: round2(e.deliveryKg), rolls: round2(e.deliveryRolls) },
      });
    }
    byParty.sort((a, b) => b.production.kg + b.delivery.kg - (a.production.kg + a.delivery.kg));
  }

  // ── Fabric breakdown ──────────────────────────────────────────────────
  const fabMap = new Map<number, { type: string; productionKg: number; productionRolls: number; deliveryKg: number; deliveryRolls: number }>();
  for (const r of rows) {
    const key = r.fabricTypeId ?? 0;
    let entry = fabMap.get(key);
    if (!entry) {
      entry = { type: r.fabricTypeName ?? (r.fabricTypeId == null ? "Unknown" : `Fabric ${r.fabricTypeId}`), productionKg: 0, productionRolls: 0, deliveryKg: 0, deliveryRolls: 0 };
      fabMap.set(key, entry);
    }
    const kg = toNum(r.kg);
    const rolls = toNum(r.rolls);
    if (r.transactionTypeId === productionId) { entry.productionKg += kg; entry.productionRolls += rolls; }
    else if (r.transactionTypeId === deliveryId) { entry.deliveryKg += kg; entry.deliveryRolls += rolls; }
  }
  const fabricBreakdown = [...fabMap.values()]
    .map((f) => ({
      type: f.type,
      productionKg: round2(f.productionKg),
      productionRolls: round2(f.productionRolls),
      deliveryKg: round2(f.deliveryKg),
      deliveryRolls: round2(f.deliveryRolls),
    }))
    .sort((a, b) => b.productionKg + b.deliveryKg - (a.productionKg + a.deliveryKg));

  // ── Daily trend (single-party view) ────────────────────────────────────
  let dailyTrend: { date: string; productionKg: number; deliveryKg: number }[] = [];
  if (partyId != null) {
    const dayMap = new Map<string, { productionKg: number; deliveryKg: number }>();
    for (const r of rows) {
      const day = String(r.date ?? "").slice(0, 10);
      if (!day) continue;
      let e = dayMap.get(day);
      if (!e) { e = { productionKg: 0, deliveryKg: 0 }; dayMap.set(day, e); }
      const kg = toNum(r.kg);
      if (r.transactionTypeId === productionId) e.productionKg += kg;
      else if (r.transactionTypeId === deliveryId) e.deliveryKg += kg;
    }
    for (let d = 1; d <= dayTo; d++) {
      const iso = `${year}-${MONTHS[month - 1]}-${String(d).padStart(2, "0")}`;
      const e = dayMap.get(iso);
      dailyTrend.push({
        date: iso,
        productionKg: round2(e?.productionKg ?? 0),
        deliveryKg: round2(e?.deliveryKg ?? 0),
      });
    }
  }

  res.json({
    party,
    window: { month, year, from, to, isCurrentMonth },
    totals: {
      production: { kg: round2(productionKg), rolls: round2(productionRolls) },
      delivery: { kg: round2(deliveryKg), rolls: round2(deliveryRolls) },
    },
    byParty,
    fabricBreakdown,
    dailyTrend,
  });
});

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

export default router;
