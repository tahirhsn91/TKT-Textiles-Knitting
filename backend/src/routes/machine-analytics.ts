import { Router, type IRouter } from "express";
import { eq, and, gte, sql } from "drizzle-orm";
import { z } from "zod/v4";
import { db } from "../db/index.js";
import {
  machineMasterTable,
  transactionTypeMasterTable,
  transactionHeaderTable,
  transactionDetailTable,
} from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";

const router: IRouter = Router();

const BASELINE = z.enum(["needle", "sinker"]);
/** The Fabric Production transaction type code (matches salary-entries.ts). */
const FABRIC_PRODUCTION_CODE = "Fabric_Production";

function daysSince(iso: string | null): number | null {
  if (!iso) return null;
  const d = new Date(iso + "T00:00:00");
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const ms = now.getTime() - d.getTime();
  if (ms < 0) return 0;
  return Math.floor(ms / 86_400_000);
}

/** Humanized duration, e.g. "8 months 2 weeks" / "263 days". */
function humanize(days: number | null): string | null {
  if (days == null) return null;
  if (days < 1) return "today";
  const years = Math.floor(days / 365);
  const months = Math.floor((days % 365) / 30);
  const weeks = Math.floor(((days % 365) % 30) / 7);
  const remDays = ((days % 365) % 30) % 7;
  const parts: string[] = [];
  if (years) parts.push(`${years} year${years > 1 ? "s" : ""}`);
  if (months) parts.push(`${months} month${months > 1 ? "s" : ""}`);
  if (!years && weeks) parts.push(`${weeks} week${weeks > 1 ? "s" : ""}`);
  if (!years && !months && remDays) parts.push(`${remDays} day${remDays > 1 ? "s" : ""}`);
  return parts.length ? parts.join(" ") : `${days} day${days > 1 ? "s" : ""}`;
}

const toNum = (v: unknown): number => {
  const n = typeof v === "string" ? parseFloat(v) : Number(v ?? 0);
  return Number.isFinite(n) ? n : 0;
};

/**
 * GET /api/machine-analytics?baseline=needle|sinker
 *
 * Per-machine fabric production since the machine's needle/sinker change date
 * (whichever baseline is requested), up to today (inclusive). Production is
 * taken from Fabric Production transactions (transaction type
 * "Fabric_Production"): each detail row carries machine_id + net_wt + quantity,
 * and its header's date must be >= the baseline change date.
 *
 * Returns ALL machines; a machine missing the requested baseline's change date
 * is excluded from that baseline's result (no window to compute). Zero-production
 * machines are included.
 */
router.get("/machine-analytics", async (req, res): Promise<void> => {
  const baselineRaw = typeof req.query.baseline === "string" ? req.query.baseline : "needle";
  const baseline = BASELINE.safeParse(baselineRaw).success ? baselineRaw : "needle";

  const changeDateCol =
    baseline === "needle" ? machineMasterTable.needleChangeDate : machineMasterTable.sinkerChangeDate;

  // Resolve the Fabric Production transaction type (same convention as salary-entries).
  const tenantId = activeTenantId(req);
  const [fabricProd] = await db
    .select()
    .from(transactionTypeMasterTable)
    .where(and(eq(transactionTypeMasterTable.code, FABRIC_PRODUCTION_CODE), eq(transactionTypeMasterTable.tenantId, tenantId)));
  if (!fabricProd) {
    res.status(500).json({ error: "Fabric Production transaction type is not configured" });
    return;
  }

  // All machines, with the baseline change date (null-safe).
  const machines = await db
    .select({
      id: machineMasterTable.id,
      machineNumber: machineMasterTable.machineNumber,
      name: machineMasterTable.name,
      changeDate: changeDateCol,
    })
    .from(machineMasterTable)
    .where(eq(machineMasterTable.tenantId, tenantId))
    .orderBy(machineMasterTable.machineNumber);

  // Per-machine production aggregates over Fabric Production transactions with
  // date >= the machine's baseline change date. Done in one grouped query so we
  // only scan the relevant detail rows.
  const rows = await db
    .select({
      machineId: transactionDetailTable.machineId,
      totalKg: sql<string>`coalesce(sum(${transactionDetailTable.netWt}), 0)`,
      totalRolls: sql<string>`coalesce(sum(${transactionDetailTable.quantity}), 0)`,
      txCount: sql<number>`count(distinct ${transactionHeaderTable.id})::int`,
    })
    .from(transactionDetailTable)
    .innerJoin(
      transactionHeaderTable,
      eq(transactionDetailTable.headerId, transactionHeaderTable.id),
    )
    .innerJoin(
      machineMasterTable,
      eq(transactionDetailTable.machineId, machineMasterTable.id),
    )
    .where(
      and(
        eq(transactionHeaderTable.transactionTypeId, fabricProd.id),
        eq(transactionDetailTable.tenantId, tenantId),
        gte(transactionHeaderTable.date, changeDateCol),
      ),
    )
    .groupBy(transactionDetailTable.machineId);

  const aggByMachine = new Map(
    rows.map((r) => [
      r.machineId,
      {
        totalKg: toNum(r.totalKg),
        totalRolls: toNum(r.totalRolls),
        txCount: r.txCount,
      },
    ]),
  );

  const now = new Date().toISOString().slice(0, 10);
  const results = [];
  let excluded = 0;

  for (const m of machines) {
    if (!m.changeDate) {
      excluded += 1;
      continue;
    }
    const agg = aggByMachine.get(m.id) ?? { totalKg: 0, totalRolls: 0, txCount: 0 };
    const days = daysSince(m.changeDate);
    results.push({
      machineId: m.id,
      machineNumber: m.machineNumber,
      machineName: m.name,
      baseline,
      changeDate: m.changeDate,
      daysSinceChange: days,
      humanizedDuration: humanize(days),
      totalKg: agg.totalKg,
      totalRolls: agg.totalRolls,
      transactionCount: agg.txCount,
      kgPerRoll: agg.totalRolls > 0 ? agg.totalKg / agg.totalRolls : 0,
    });
  }

  // Ranking: most production → least (by kg).
  results.sort((a, b) => b.totalKg - a.totalKg);

  res.json({
    baseline,
    computedTo: now,
    machineCount: results.length,
    excludedCount: excluded,
    rows: results,
  });
});

export default router;
