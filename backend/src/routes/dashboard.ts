import { Router, type IRouter } from "express";
import { and, eq, gte, lte, sql, count, sum } from "drizzle-orm";
import { db } from "../db/index.js";
import {
  transactionHeaderTable,
  transactionDetailTable,
  fabricTypeMasterTable,
  partyMasterTable,
  machineMasterTable,
  employeeMasterTable,
} from "../db/index.js";

const router: IRouter = Router();

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

async function getKpis() {
  const { cmFrom, cmTo, periodLabel } = getWindow();

  const [txnCountRow] = await db
    .select({ totalTransactions: count(transactionHeaderTable.id) })
    .from(transactionHeaderTable)
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)));

  const [netWtRow] = await db
    .select({ totalNetWeight: sum(transactionDetailTable.netWt) })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)));

  const [activeMachinesRow] = await db
    .select({ activeMachines: sql<number>`COUNT(DISTINCT ${transactionDetailTable.machineId})` })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)));

  return {
    totalTransactions: toNum(txnCountRow?.totalTransactions),
    totalNetWeight: toNum(netWtRow?.totalNetWeight),
    activeMachines: toNum(activeMachinesRow?.activeMachines),
    periodLabel,
  };
}

async function getMonthlyTrend() {
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
    .where(and(gte(transactionHeaderTable.date, trendFrom), lte(transactionHeaderTable.date, cmTo)))
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

async function getDailyProduction() {
  const { dailyFrom, todayStr } = getWindow();
  const rows = await db
    .select({
      date: transactionHeaderTable.date,
      totalQuantity: sum(transactionDetailTable.quantity),
      totalNetWeight: sum(transactionDetailTable.netWt),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .where(and(gte(transactionHeaderTable.date, dailyFrom), lte(transactionHeaderTable.date, todayStr)))
    .groupBy(transactionHeaderTable.date)
    .orderBy(transactionHeaderTable.date);

  return rows.map((r) => ({
    date: r.date,
    quantity: toNum(r.totalQuantity),
    netWeight: toNum(r.totalNetWeight),
  }));
}

async function getFabricBreakdown() {
  const { cmFrom, cmTo } = getWindow();
  const rows = await db
    .select({
      fabricType: fabricTypeMasterTable.name,
      totalNetWeight: sum(transactionDetailTable.netWt),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .leftJoin(fabricTypeMasterTable, eq(transactionHeaderTable.fabricTypeId, fabricTypeMasterTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)))
    .groupBy(fabricTypeMasterTable.name)
    .orderBy(sql`SUM(${transactionDetailTable.netWt}) DESC`);

  return rows.map((r) => ({ name: r.fabricType ?? "Unknown", value: toNum(r.totalNetWeight) }));
}

async function getTopParties() {
  const { cmFrom, cmTo } = getWindow();
  const rows = await db
    .select({
      partyName: partyMasterTable.name,
      transactionCount: count(transactionHeaderTable.id),
    })
    .from(transactionHeaderTable)
    .leftJoin(partyMasterTable, eq(transactionHeaderTable.partyId, partyMasterTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)))
    .groupBy(partyMasterTable.name)
    .orderBy(sql`COUNT(${transactionHeaderTable.id}) DESC`)
    .limit(10);

  return rows.map((r) => ({ name: r.partyName ?? "Unknown", count: toNum(r.transactionCount) }));
}

async function getMachineUtilization() {
  const { cmFrom, cmTo } = getWindow();
  const rows = await db
    .select({
      machineName: machineMasterTable.name,
      transactionLines: count(transactionDetailTable.id),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .leftJoin(machineMasterTable, eq(transactionDetailTable.machineId, machineMasterTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)))
    .groupBy(machineMasterTable.name)
    .orderBy(sql`COUNT(${transactionDetailTable.id}) DESC`)
    .limit(15);

  return rows.map((r) => ({ name: r.machineName ?? "Unknown", lines: toNum(r.transactionLines) }));
}

async function getEmployeeOutput() {
  const { cmFrom, cmTo } = getWindow();
  const rows = await db
    .select({
      employeeName: employeeMasterTable.name,
      totalNetWeight: sum(transactionDetailTable.netWt),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .leftJoin(employeeMasterTable, eq(transactionDetailTable.machineEmployeeId, employeeMasterTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)))
    .groupBy(employeeMasterTable.name)
    .orderBy(sql`SUM(${transactionDetailTable.netWt}) DESC`)
    .limit(10);

  return rows.map((r) => ({ name: r.employeeName ?? "Unknown", netWeight: toNum(r.totalNetWeight) }));
}

// ── Per-widget endpoints ────────────────────────────────────────────────────
router.get("/dashboard/kpis",                async (_req, res) => { res.json(await getKpis()); });
router.get("/dashboard/monthly-trend",       async (_req, res) => { res.json(await getMonthlyTrend()); });
router.get("/dashboard/daily-production",    async (_req, res) => { res.json(await getDailyProduction()); });
router.get("/dashboard/fabric-breakdown",    async (_req, res) => { res.json(await getFabricBreakdown()); });
router.get("/dashboard/top-parties",         async (_req, res) => { res.json(await getTopParties()); });
router.get("/dashboard/machine-utilization", async (_req, res) => { res.json(await getMachineUtilization()); });
router.get("/dashboard/employee-output",     async (_req, res) => { res.json(await getEmployeeOutput()); });

// ── Aggregated summary (kept for backward compatibility) ────────────────────
router.get("/dashboard/summary", async (_req, res): Promise<void> => {
  const [kpis, monthlyTrend, dailyProduction, fabricBreakdown, topParties, machineUtilization, employeeOutput] =
    await Promise.all([
      getKpis(),
      getMonthlyTrend(),
      getDailyProduction(),
      getFabricBreakdown(),
      getTopParties(),
      getMachineUtilization(),
      getEmployeeOutput(),
    ]);

  res.json({ kpis, monthlyTrend, dailyProduction, fabricBreakdown, topParties, machineUtilization, employeeOutput });
});

export default router;
