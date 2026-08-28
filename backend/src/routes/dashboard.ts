import { Router, type IRouter } from "express";
import { and, eq, gte, lte, ne, sql, count, sum } from "drizzle-orm";
import { db } from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";
import {
  transactionHeaderTable,
  transactionDetailTable,
  transactionTypeMasterTable,
  yarnReceiptHeaderTable,
  yarnReceiptDetailTable,
  fabricTypeMasterTable,
  partyMasterTable,
  machineMasterTable,
  employeeMasterTable,
} from "../db/index.js";

const router: IRouter = Router();

// ── In-memory dashboard cache (issue #24) ───────────────────────────────────
// The dashboard runs several heavier queries on every request. Cache each
// widget's result for a short TTL so repeated refreshes don't hammer Postgres.
// A 60s window means the numbers can lag up to a minute behind a mutation,
// which is acceptable for a dashboard overview (data settles over the day).
const DASHBOARD_CACHE_TTL_MS = 60_000;
const dashboardCache = new Map<string, { data: unknown; expiresAt: number }>();

function withCache<T>(key: string, compute: () => Promise<T>): () => Promise<T> {
  return async () => {
    const now = Date.now();
    const hit = dashboardCache.get(key);
    if (hit && hit.expiresAt > now) {
      return hit.data as T;
    }
    const data = await compute();
    dashboardCache.set(key, { data, expiresAt: now + DASHBOARD_CACHE_TTL_MS });
    return data;
  };
}

function toNum(val: unknown): number {
  const n = parseFloat(String(val ?? ""));
  return isNaN(n) ? 0 : n;
}

const MONTHS_SHORT = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

// ── Shared date windows (constants, not data — safe to recompute per call) ───
function getWindow() {
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth() + 1;

  const cmFrom = `${currentYear}-${String(currentMonth).padStart(2, "0")}-01`;
  const lastDay = new Date(currentYear, currentMonth, 0).getDate();
  const cmTo = `${currentYear}-${String(currentMonth).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;

  // Last 12 months window
  const twelveMonthsAgo = new Date(now);
  twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 11);
  twelveMonthsAgo.setDate(1);
  const trendFrom = `${twelveMonthsAgo.getFullYear()}-${String(twelveMonthsAgo.getMonth() + 1).padStart(2, "0")}-01`;

  // Last 30 days
  const thirtyDaysAgo = new Date(now);
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 29);
  const dailyFrom = `${thirtyDaysAgo.getFullYear()}-${String(thirtyDaysAgo.getMonth() + 1).padStart(2, "0")}-${String(thirtyDaysAgo.getDate()).padStart(2, "0")}`;
  const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;

  const periodLabel = `${now.toLocaleString("default", { month: "long" })} ${currentYear}`;

  return { cmFrom, cmTo, trendFrom, dailyFrom, todayStr, periodLabel };
}

// ── Widget data functions ───────────────────────────────────────────────────

async function getKpis(tenantId: number) {
  const { cmFrom, cmTo, periodLabel } = getWindow();

  // Net weight produced = fabric production transactions (excludes dispatches/
  // receipts, which also carry net_wt but are not production).
  const [netWtRow] = await db
    .select({ totalNetWeight: sum(transactionDetailTable.netWt) })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .innerJoin(transactionTypeMasterTable, eq(transactionHeaderTable.transactionTypeId, transactionTypeMasterTable.id))
    .where(and(
      gte(transactionHeaderTable.date, cmFrom),
      lte(transactionHeaderTable.date, cmTo),
      eq(transactionHeaderTable.tenantId, tenantId),
      eq(transactionTypeMasterTable.code, "Fabric_Production"),
    ));

  // Net weight delivered = fabric delivery transactions (Fabric_Dispatch).
  const [netWtDeliveredRow] = await db
    .select({ totalNetWeight: sum(transactionDetailTable.netWt) })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .innerJoin(transactionTypeMasterTable, eq(transactionHeaderTable.transactionTypeId, transactionTypeMasterTable.id))
    .where(and(
      gte(transactionHeaderTable.date, cmFrom),
      lte(transactionHeaderTable.date, cmTo),
      eq(transactionHeaderTable.tenantId, tenantId),
      eq(transactionTypeMasterTable.code, "Fabric_Dispatch"),
    ));

  // Net weight yarn receipt — yarn receipts live in their own tables
  // (yarn_receipt_header / yarn_receipt_detail), not transaction_header, and
  // the date is receipt_date. Exclude cancelled receipts.
  const [netWtYarnReceiptRow] = await db
    .select({ totalNetWeight: sum(yarnReceiptDetailTable.netWeight) })
    .from(yarnReceiptDetailTable)
    .innerJoin(yarnReceiptHeaderTable, eq(yarnReceiptDetailTable.headerId, yarnReceiptHeaderTable.id))
    .where(and(
      gte(yarnReceiptHeaderTable.receiptDate, cmFrom),
      lte(yarnReceiptHeaderTable.receiptDate, cmTo),
      eq(yarnReceiptHeaderTable.tenantId, tenantId),
      ne(yarnReceiptHeaderTable.status, "cancelled"),
    ));

  const [activeMachinesRow] = await db
    .select({ activeMachines: sql<number>`COUNT(DISTINCT ${transactionDetailTable.machineId})` })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo), eq(transactionHeaderTable.tenantId, tenantId)));

  return {
    totalNetWeight: toNum(netWtRow?.totalNetWeight),
    netWeightDelivered: toNum(netWtDeliveredRow?.totalNetWeight),
    netWeightYarnReceipt: toNum(netWtYarnReceiptRow?.totalNetWeight),
    activeMachines: toNum(activeMachinesRow?.activeMachines),
    periodLabel,
  };
}

async function getMonthlyTrend(tenantId: number) {
  const { trendFrom, cmTo } = getWindow();
  const rows = await db
    .select({
      year: sql<number>`EXTRACT(YEAR FROM ${transactionHeaderTable.date})`,
      month: sql<number>`EXTRACT(MONTH FROM ${transactionHeaderTable.date})`,
      totalNetWeight: sum(transactionDetailTable.netWt),
      totalQuantity: sum(transactionDetailTable.quantity),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .innerJoin(transactionTypeMasterTable, eq(transactionHeaderTable.transactionTypeId, transactionTypeMasterTable.id))
    .where(and(
      gte(transactionHeaderTable.date, trendFrom),
      lte(transactionHeaderTable.date, cmTo),
      eq(transactionHeaderTable.tenantId, tenantId),
      eq(transactionTypeMasterTable.code, "Fabric_Production"),
    ))
    .groupBy(
      sql`EXTRACT(YEAR FROM ${transactionHeaderTable.date})`,
      sql`EXTRACT(MONTH FROM ${transactionHeaderTable.date})`,
    )
    .orderBy(
      sql`EXTRACT(YEAR FROM ${transactionHeaderTable.date})`,
      sql`EXTRACT(MONTH FROM ${transactionHeaderTable.date})`,
    );

  return rows.map((r) => ({
    label: `${MONTHS_SHORT[toNum(r.month) - 1]} ${String(toNum(r.year)).slice(2)}`,
    netWeight: toNum(r.totalNetWeight),
    quantity: toNum(r.totalQuantity),
  }));
}

async function getDailyProduction(tenantId: number) {
  const { dailyFrom, todayStr } = getWindow();
  const rows = await db
    .select({
      date: transactionHeaderTable.date,
      totalQuantity: sum(transactionDetailTable.quantity),
      totalNetWeight: sum(transactionDetailTable.netWt),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .where(and(gte(transactionHeaderTable.date, dailyFrom), lte(transactionHeaderTable.date, todayStr), eq(transactionHeaderTable.tenantId, tenantId)))
    .groupBy(transactionHeaderTable.date)
    .orderBy(transactionHeaderTable.date);

  return rows.map((r) => ({
    date: r.date,
    quantity: toNum(r.totalQuantity),
    netWeight: toNum(r.totalNetWeight),
  }));
}

async function getFabricBreakdown(tenantId: number) {
  const { cmFrom, cmTo } = getWindow();
  const rows = await db
    .select({
      fabricType: fabricTypeMasterTable.name,
      totalNetWeight: sum(transactionDetailTable.netWt),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .innerJoin(transactionTypeMasterTable, eq(transactionHeaderTable.transactionTypeId, transactionTypeMasterTable.id))
    .leftJoin(fabricTypeMasterTable, eq(transactionHeaderTable.fabricTypeId, fabricTypeMasterTable.id))
    .where(and(
      gte(transactionHeaderTable.date, cmFrom),
      lte(transactionHeaderTable.date, cmTo),
      eq(transactionHeaderTable.tenantId, tenantId),
      eq(transactionTypeMasterTable.code, "Fabric_Production"),
    ))
    .groupBy(fabricTypeMasterTable.name)
    .orderBy(sql`SUM(${transactionDetailTable.netWt}) DESC`);

  return rows.map((r) => ({ name: r.fabricType ?? "Unknown", value: toNum(r.totalNetWeight) }));
}

async function getTopParties(tenantId: number) {
  const { cmFrom, cmTo } = getWindow();
  // Per party: net weight produced (Fabric_Production) vs delivered
  // (Fabric_Dispatch) this month, as two series on the same bar.
  const rows = await db
    .select({
      partyName: partyMasterTable.name,
      produced: sql<number>`SUM(CASE WHEN ${transactionTypeMasterTable.code} = 'Fabric_Production' THEN ${transactionDetailTable.netWt} ELSE 0 END)`,
      delivered: sql<number>`SUM(CASE WHEN ${transactionTypeMasterTable.code} = 'Fabric_Dispatch' THEN ${transactionDetailTable.netWt} ELSE 0 END)`,
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .innerJoin(transactionTypeMasterTable, eq(transactionHeaderTable.transactionTypeId, transactionTypeMasterTable.id))
    .leftJoin(partyMasterTable, eq(transactionHeaderTable.partyId, partyMasterTable.id))
    .where(and(
      gte(transactionHeaderTable.date, cmFrom),
      lte(transactionHeaderTable.date, cmTo),
      eq(transactionHeaderTable.tenantId, tenantId),
      sql`${transactionTypeMasterTable.code} IN ('Fabric_Production', 'Fabric_Dispatch')`,
    ))
    .groupBy(partyMasterTable.name)
    .orderBy(sql`SUM(${transactionDetailTable.netWt}) DESC`)
    .limit(10);

  return rows.map((r) => ({ name: r.partyName ?? "Unknown", produced: toNum(r.produced), delivered: toNum(r.delivered) }));
}

async function getMachineUtilization(tenantId: number) {
  const { cmFrom, cmTo } = getWindow();
  const rows = await db
    .select({
      machineName: machineMasterTable.name,
      transactionLines: count(transactionDetailTable.id),
      totalNetWeight: sum(transactionDetailTable.netWt),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .innerJoin(transactionTypeMasterTable, eq(transactionHeaderTable.transactionTypeId, transactionTypeMasterTable.id))
    .leftJoin(machineMasterTable, eq(transactionDetailTable.machineId, machineMasterTable.id))
    .where(and(
      gte(transactionHeaderTable.date, cmFrom),
      lte(transactionHeaderTable.date, cmTo),
      eq(transactionHeaderTable.tenantId, tenantId),
      eq(transactionTypeMasterTable.code, "Fabric_Production"),
    ))
    .groupBy(machineMasterTable.name)
    .orderBy(sql`COUNT(${transactionDetailTable.id}) DESC`)
    .limit(15);

  return rows.map((r) => ({ name: r.machineName ?? "Unknown", lines: toNum(r.transactionLines), netWeight: toNum(r.totalNetWeight) }));
}

async function getEmployeeOutput(tenantId: number) {
  const { cmFrom, cmTo } = getWindow();
  const rows = await db
    .select({
      employeeName: employeeMasterTable.name,
      totalNetWeight: sum(transactionDetailTable.netWt),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .leftJoin(employeeMasterTable, eq(transactionDetailTable.employeeId, employeeMasterTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo), eq(transactionHeaderTable.tenantId, tenantId)))
    .groupBy(employeeMasterTable.name)
    .orderBy(sql`SUM(${transactionDetailTable.netWt}) DESC`)
    .limit(10);

  return rows.map((r) => ({ name: r.employeeName ?? "Unknown", netWeight: toNum(r.totalNetWeight) }));
}

// ── Cached widget getters (TTL-cached, keyed by tenant so no cross-tenant leak) ─
const getCachedKpis = (t: number) => withCache(`kpis:${t}`, () => getKpis(t));
const getCachedMonthlyTrend = (t: number) => withCache(`monthly-trend:${t}`, () => getMonthlyTrend(t));
const getCachedDailyProduction = (t: number) => withCache(`daily-production:${t}`, () => getDailyProduction(t));
const getCachedFabricBreakdown = (t: number) => withCache(`fabric-breakdown:${t}`, () => getFabricBreakdown(t));
const getCachedTopParties = (t: number) => withCache(`top-parties:${t}`, () => getTopParties(t));
const getCachedMachineUtilization = (t: number) => withCache(`machine-utilization:${t}`, () => getMachineUtilization(t));
const getCachedEmployeeOutput = (t: number) => withCache(`employee-output:${t}`, () => getEmployeeOutput(t));

// ── Per-widget endpoints ────────────────────────────────────────────────────
router.get("/dashboard/kpis",                async (req, res) => { res.json(await getCachedKpis(activeTenantId(req))()); });
router.get("/dashboard/monthly-trend",       async (req, res) => { res.json(await getCachedMonthlyTrend(activeTenantId(req))()); });
router.get("/dashboard/daily-production",    async (req, res) => { res.json(await getCachedDailyProduction(activeTenantId(req))()); });
router.get("/dashboard/fabric-breakdown",    async (req, res) => { res.json(await getCachedFabricBreakdown(activeTenantId(req))()); });
router.get("/dashboard/top-parties",         async (req, res) => { res.json(await getCachedTopParties(activeTenantId(req))()); });
router.get("/dashboard/machine-utilization", async (req, res) => { res.json(await getCachedMachineUtilization(activeTenantId(req))()); });
router.get("/dashboard/employee-output",     async (req, res) => { res.json(await getCachedEmployeeOutput(activeTenantId(req))()); });

// ── Aggregated summary (kept for backward compatibility) ────────────────────
router.get("/dashboard/summary", async (req, res): Promise<void> => {
  const t = activeTenantId(req);
  const [kpis, monthlyTrend, dailyProduction, fabricBreakdown, topParties, machineUtilization, employeeOutput] =
    await Promise.all([
      getCachedKpis(t)(),
      getCachedMonthlyTrend(t)(),
      getCachedDailyProduction(t)(),
      getCachedFabricBreakdown(t)(),
      getCachedTopParties(t)(),
      getCachedMachineUtilization(t)(),
      getCachedEmployeeOutput(t)(),
    ]);

  res.json({ kpis, monthlyTrend, dailyProduction, fabricBreakdown, topParties, machineUtilization, employeeOutput });
});

export default router;
