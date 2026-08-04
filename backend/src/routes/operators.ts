import { Router, type IRouter } from "express";
import { eq, and, gte, lte, sql } from "drizzle-orm";
import { db } from "../db/index.js";
import {
  machineOperatorMasterTable,
  operatorSalaryRecordsTable,
  operatorAdvancesTable,
} from "../db/index.js";

const router: IRouter = Router();

function idParam(req: { params: Record<string, string> }) {
  const id = parseInt(req.params.id);
  return isNaN(id) ? null : id;
}

/**
 * Strict numeric parser for client input (issue #23). Unlike the old toNum(),
 * it does NOT silently map NULL/NaN to 0 — an invalid amount is rejected with
 * a 400 instead of being stored as zero. Returns null for NULL/empty/NaN so
 * callers can distinguish "missing" from "zero".
 */
function toNumStrict(val: unknown): number | null {
  if (val === null || val === undefined || val === "") return null;
  const n = Number(val);
  return Number.isFinite(n) ? n : null;
}

// ─── Advances ────────────────────────────────────────────────────────────────

router.get("/operators/advances", async (req, res): Promise<void> => {
  const { operatorId, dateFrom, dateTo } = req.query as Record<string, string>;
  const conditions = [];
  if (operatorId) conditions.push(eq(operatorAdvancesTable.operatorId, Number(operatorId)));
  if (dateFrom) conditions.push(gte(operatorAdvancesTable.date, dateFrom));
  if (dateTo) conditions.push(lte(operatorAdvancesTable.date, dateTo));

  const rows = await db
    .select({
      id: operatorAdvancesTable.id,
      operatorId: operatorAdvancesTable.operatorId,
      operatorName: machineOperatorMasterTable.name,
      date: operatorAdvancesTable.date,
      amount: operatorAdvancesTable.amount,
      notes: operatorAdvancesTable.notes,
      createdAt: operatorAdvancesTable.createdAt,
    })
    .from(operatorAdvancesTable)
    .leftJoin(machineOperatorMasterTable, eq(operatorAdvancesTable.operatorId, machineOperatorMasterTable.id))
    .where(conditions.length > 0 ? and(...conditions) : undefined)
    .orderBy(operatorAdvancesTable.date);
  res.json(rows);
});

router.post("/operators/advances", async (req, res): Promise<void> => {
  const { operatorId, date, amount, notes } = req.body;
  if (!operatorId || !date || amount === undefined) {
    res.status(400).json({ error: "operatorId, date, and amount are required" });
    return;
  }
  const amt = toNumStrict(amount);
  if (amt === null) {
    res.status(400).json({ error: "amount must be a valid number" });
    return;
  }
  if (amt < 0) { res.status(400).json({ error: "amount must be >= 0" }); return; }
  const [row] = await db
    .insert(operatorAdvancesTable)
    .values({ operatorId: Number(operatorId), date, amount: String(amt), notes: notes || null })
    .returning();
  res.status(201).json(row);
});

router.delete("/operators/advances/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db
    .delete(operatorAdvancesTable)
    .where(eq(operatorAdvancesTable.id, id))
    .returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Payroll Summary ─────────────────────────────────────────────────────────

router.get("/operators/payroll-summary", async (req, res): Promise<void> => {
  const { month, year, operatorId } = req.query as Record<string, string>;
  if (!month || !year) {
    res.status(400).json({ error: "month and year are required" });
    return;
  }
  const m = parseInt(month);
  const y = parseInt(year);
  const dateFrom = `${y}-${String(m).padStart(2, "0")}-01`;
  const lastDay = new Date(y, m, 0).getDate();
  const dateTo = `${y}-${String(m).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;

  const opConditions = [];
  const advConditions = [gte(operatorAdvancesTable.date, dateFrom), lte(operatorAdvancesTable.date, dateTo)];
  const recConditions = [gte(operatorSalaryRecordsTable.date, dateFrom), lte(operatorSalaryRecordsTable.date, dateTo)];

  if (operatorId) {
    opConditions.push(eq(machineOperatorMasterTable.id, Number(operatorId)));
    advConditions.push(eq(operatorAdvancesTable.operatorId, Number(operatorId)));
    recConditions.push(eq(operatorSalaryRecordsTable.operatorId, Number(operatorId)));
  }

  const operators = await db
    .select({ id: machineOperatorMasterTable.id, name: machineOperatorMasterTable.name, code: machineOperatorMasterTable.code })
    .from(machineOperatorMasterTable)
    .where(opConditions.length > 0 ? and(...opConditions) : undefined)
    .orderBy(machineOperatorMasterTable.name);

  const records = await db
    .select()
    .from(operatorSalaryRecordsTable)
    .where(and(...recConditions));

  const advances = await db
    .select()
    .from(operatorAdvancesTable)
    .where(and(...advConditions));

  // Totals are aggregated in SQL with COALESCE so a NULL column value
  // contributes 0 explicitly in the DB layer — never silently coerced by a JS
  // helper (issue #23). Detail rows are still returned raw for the PDF's
  // daily breakdown; the frontend formats them for display.
  const salaryTotals = await db
    .select({
      operatorId: operatorSalaryRecordsTable.operatorId,
      totalDaysWorked: sql<number>`count(*)::int`,
      totalSalary: sql<string>`coalesce(sum(${operatorSalaryRecordsTable.finalSalary}), 0)`,
    })
    .from(operatorSalaryRecordsTable)
    .where(and(...recConditions))
    .groupBy(operatorSalaryRecordsTable.operatorId);

  const advanceTotals = await db
    .select({
      operatorId: operatorAdvancesTable.operatorId,
      totalAdvances: sql<string>`coalesce(sum(${operatorAdvancesTable.amount}), 0)`,
    })
    .from(operatorAdvancesTable)
    .where(and(...advConditions))
    .groupBy(operatorAdvancesTable.operatorId);

  const salaryByOperator = new Map(salaryTotals.map((t) => [t.operatorId, t]));
  const advanceByOperator = new Map(advanceTotals.map((t) => [t.operatorId, t]));

  const summary = operators.map((op) => {
    const opRecords = records.filter((r) => r.operatorId === op.id);
    const opAdvances = advances.filter((a) => a.operatorId === op.id);
    const salaryTotal = salaryByOperator.get(op.id);
    const advanceTotal = advanceByOperator.get(op.id);
    const totalSalary = Number(salaryTotal?.totalSalary ?? 0);
    const totalAdvances = Number(advanceTotal?.totalAdvances ?? 0);
    const totalDaysWorked = salaryTotal?.totalDaysWorked ?? 0;
    const netPayable = totalSalary - totalAdvances;
    return {
      operatorId: op.id,
      operatorName: op.name,
      operatorCode: op.code,
      totalDaysWorked,
      totalSalary,
      totalAdvances,
      netPayable,
      records: opRecords,
      advances: opAdvances,
    };
  });

  res.json(summary);
});

export default router;
