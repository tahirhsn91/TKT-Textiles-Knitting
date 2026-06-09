import { Router, type IRouter } from "express";
import { and, eq, gte, lte, sql, count, sum } from "drizzle-orm";
import { db } from "../db/index.js";
import {
  transactionHeaderTable,
  transactionDetailTable,
  fabricTypeMasterTable,
  partyMasterTable,
  machineMasterTable,
  machineOperatorMasterTable,
  operatorSalarySettingsTable,
  operatorSalaryRecordsTable,
  operatorAdvancesTable,
} from "../db/index.js";

const router: IRouter = Router();

function toNum(val: unknown): number {
  const n = parseFloat(String(val ?? ""));
  return isNaN(n) ? 0 : n;
}

router.get("/dashboard/summary", async (_req, res): Promise<void> => {
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

  // ── KPIs: current month ─────────────────────────────────────────────────
  // Count distinct transaction headers (not detail lines)
  const [txnCountRow] = await db
    .select({ totalTransactions: count(transactionHeaderTable.id) })
    .from(transactionHeaderTable)
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)));

  const [netWtRow] = await db
    .select({ totalNetWeight: sum(transactionDetailTable.netWt) })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)));

  // Active machines: distinct machines with at least one detail in current month
  const [activeMachinesRow] = await db
    .select({ activeMachines: sql<number>`COUNT(DISTINCT ${transactionDetailTable.machineId})` })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)));

  // ── Monthly production trend (last 12 months) ───────────────────────────
  const monthlyTrend = await db
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

  // ── Daily production (last 30 days) ─────────────────────────────────────
  const dailyProduction = await db
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

  // ── Fabric type breakdown (current month) ───────────────────────────────
  const fabricBreakdown = await db
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

  // ── Top parties by transaction count (current month) ────────────────────
  const topParties = await db
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

  // ── Machine utilization (current month) ─────────────────────────────────
  const machineUtilization = await db
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

  // ── Top operators by net weight (current month) ──────────────────────────
  const operatorOutput = await db
    .select({
      operatorName: machineOperatorMasterTable.name,
      totalNetWeight: sum(transactionDetailTable.netWt),
    })
    .from(transactionDetailTable)
    .innerJoin(transactionHeaderTable, eq(transactionDetailTable.headerId, transactionHeaderTable.id))
    .leftJoin(machineOperatorMasterTable, eq(transactionDetailTable.machineOperatorId, machineOperatorMasterTable.id))
    .where(and(gte(transactionHeaderTable.date, cmFrom), lte(transactionHeaderTable.date, cmTo)))
    .groupBy(machineOperatorMasterTable.name)
    .orderBy(sql`SUM(${transactionDetailTable.netWt}) DESC`)
    .limit(10);

  // ── Payroll breakdown (latest salary period) ────────────────────────────
  // Determine the most recent month/year that has any salary records
  const [latestRecord] = await db
    .select({ date: operatorSalaryRecordsTable.date })
    .from(operatorSalaryRecordsTable)
    .orderBy(sql`${operatorSalaryRecordsTable.date} DESC`)
    .limit(1);

  let payrollFrom = cmFrom;
  let payrollTo = cmTo;
  let payrollPeriodLabel = `${now.toLocaleString("default", { month: "long" })} ${currentYear}`;

  if (latestRecord) {
    const latestDate = new Date(latestRecord.date);
    const pYear = latestDate.getFullYear();
    const pMonth = latestDate.getMonth() + 1;
    payrollFrom = `${pYear}-${String(pMonth).padStart(2, "0")}-01`;
    const pLastDay = new Date(pYear, pMonth, 0).getDate();
    payrollTo = `${pYear}-${String(pMonth).padStart(2, "0")}-${String(pLastDay).padStart(2, "0")}`;
    const MONTH_NAMES = ["January","February","March","April","May","June","July","August","September","October","November","December"];
    payrollPeriodLabel = `${MONTH_NAMES[pMonth - 1]} ${pYear}`;
  }

  const operators = await db
    .select({ id: machineOperatorMasterTable.id, name: machineOperatorMasterTable.name })
    .from(machineOperatorMasterTable)
    .orderBy(machineOperatorMasterTable.name);

  const salaryRecords = await db
    .select()
    .from(operatorSalaryRecordsTable)
    .where(and(gte(operatorSalaryRecordsTable.date, payrollFrom), lte(operatorSalaryRecordsTable.date, payrollTo)));

  const advances = await db
    .select()
    .from(operatorAdvancesTable)
    .where(and(gte(operatorAdvancesTable.date, payrollFrom), lte(operatorAdvancesTable.date, payrollTo)));

  const payrollBreakdown = operators
    .map((op) => {
      const opRecords = salaryRecords.filter((r) => r.operatorId === op.id);
      const opAdvances = advances.filter((a) => a.operatorId === op.id);
      const baseWages = opRecords.reduce((s, r) => s + toNum(r.baseWage), 0);
      const commissions = opRecords.reduce((s, r) => {
        const finalSalary = toNum(r.finalSalary);
        const base = toNum(r.baseWage);
        return s + Math.max(0, finalSalary - base);
      }, 0);
      const totalAdvances = opAdvances.reduce((s, a) => s + toNum(a.amount), 0);
      const netPayable = opRecords.reduce((s, r) => s + toNum(r.finalSalary), 0) - totalAdvances;
      return { operatorName: op.name, baseWages, commissions, advances: totalAdvances, netPayable };
    })
    .filter((op) => op.baseWages > 0 || op.commissions > 0 || op.advances > 0);

  const totalPayrollDue = payrollBreakdown.reduce((s, op) => s + op.netPayable, 0);

  res.json({
    kpis: {
      totalTransactions: toNum(txnCountRow?.totalTransactions),
      totalNetWeight: toNum(netWtRow?.totalNetWeight),
      activeMachines: toNum(activeMachinesRow?.activeMachines),
      payrollDue: totalPayrollDue,
      periodLabel: `${now.toLocaleString("default", { month: "long" })} ${currentYear}`,
    },
    payrollPeriodLabel,
    monthlyTrend: monthlyTrend.map((r) => ({
      label: `${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][toNum(r.month) - 1]} ${String(toNum(r.year)).slice(2)}`,
      netWeight: toNum(r.totalNetWeight),
      quantity: toNum(r.totalQuantity),
    })),
    dailyProduction: dailyProduction.map((r) => ({
      date: r.date,
      quantity: toNum(r.totalQuantity),
      netWeight: toNum(r.totalNetWeight),
    })),
    fabricBreakdown: fabricBreakdown.map((r) => ({
      name: r.fabricType ?? "Unknown",
      value: toNum(r.totalNetWeight),
    })),
    topParties: topParties.map((r) => ({
      name: r.partyName ?? "Unknown",
      count: toNum(r.transactionCount),
    })),
    machineUtilization: machineUtilization.map((r) => ({
      name: r.machineName ?? "Unknown",
      lines: toNum(r.transactionLines),
    })),
    operatorOutput: operatorOutput.map((r) => ({
      name: r.operatorName ?? "Unknown",
      netWeight: toNum(r.totalNetWeight),
    })),
    payrollBreakdown,
  });
});

export default router;
