import { Router, type IRouter } from "express";
import { eq, and, gte, lte, sql } from "drizzle-orm";
import { db } from "../db/index.js";
import {
  employeeMasterTable,
  employeeSalaryRecordsTable,
  employeeAdvancesTable,
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

router.get("/employees/advances", async (req, res): Promise<void> => {
  const { employeeId, dateFrom, dateTo } = req.query as Record<string, string>;
  const conditions = [];
  if (employeeId) conditions.push(eq(employeeAdvancesTable.employeeId, Number(employeeId)));
  if (dateFrom) conditions.push(gte(employeeAdvancesTable.date, dateFrom));
  if (dateTo) conditions.push(lte(employeeAdvancesTable.date, dateTo));

  const rows = await db
    .select({
      id: employeeAdvancesTable.id,
      employeeId: employeeAdvancesTable.employeeId,
      employeeName: employeeMasterTable.name,
      date: employeeAdvancesTable.date,
      amount: employeeAdvancesTable.amount,
      notes: employeeAdvancesTable.notes,
      createdAt: employeeAdvancesTable.createdAt,
    })
    .from(employeeAdvancesTable)
    .leftJoin(employeeMasterTable, eq(employeeAdvancesTable.employeeId, employeeMasterTable.id))
    .where(conditions.length > 0 ? and(...conditions) : undefined)
    .orderBy(employeeAdvancesTable.date);
  res.json(rows);
});

router.post("/employees/advances", async (req, res): Promise<void> => {
  const { employeeId, date, amount, notes } = req.body;
  if (!employeeId || !date || amount === undefined) {
    res.status(400).json({ error: "employeeId, date, and amount are required" });
    return;
  }
  const amt = toNumStrict(amount);
  if (amt === null) {
    res.status(400).json({ error: "amount must be a valid number" });
    return;
  }
  if (amt < 0) { res.status(400).json({ error: "amount must be >= 0" }); return; }
  const [row] = await db
    .insert(employeeAdvancesTable)
    .values({ employeeId: Number(employeeId), date, amount: String(amt), notes: notes || null })
    .returning();
  res.status(201).json(row);
});

router.delete("/employees/advances/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db
    .delete(employeeAdvancesTable)
    .where(eq(employeeAdvancesTable.id, id))
    .returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Payroll Summary ─────────────────────────────────────────────────────────

router.get("/employees/payroll-summary", async (req, res): Promise<void> => {
  const { month, year, employeeId } = req.query as Record<string, string>;
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
  const advConditions = [gte(employeeAdvancesTable.date, dateFrom), lte(employeeAdvancesTable.date, dateTo)];
  const recConditions = [gte(employeeSalaryRecordsTable.date, dateFrom), lte(employeeSalaryRecordsTable.date, dateTo)];

  if (employeeId) {
    opConditions.push(eq(employeeMasterTable.id, Number(employeeId)));
    advConditions.push(eq(employeeAdvancesTable.employeeId, Number(employeeId)));
    recConditions.push(eq(employeeSalaryRecordsTable.employeeId, Number(employeeId)));
  }

  const employees = await db
    .select({ id: employeeMasterTable.id, name: employeeMasterTable.name, code: employeeMasterTable.code })
    .from(employeeMasterTable)
    .where(opConditions.length > 0 ? and(...opConditions) : undefined)
    .orderBy(employeeMasterTable.name);

  const records = await db
    .select()
    .from(employeeSalaryRecordsTable)
    .where(and(...recConditions));

  const advances = await db
    .select()
    .from(employeeAdvancesTable)
    .where(and(...advConditions));

  // Totals are aggregated in SQL with COALESCE so a NULL column value
  // contributes 0 explicitly in the DB layer — never silently coerced by a JS
  // helper (issue #23). Detail rows are still returned raw for the PDF's
  // daily breakdown; the frontend formats them for display.
  const salaryTotals = await db
    .select({
      employeeId: employeeSalaryRecordsTable.employeeId,
      totalDaysWorked: sql<number>`count(*)::int`,
      totalSalary: sql<string>`coalesce(sum(${employeeSalaryRecordsTable.finalSalary}), 0)`,
    })
    .from(employeeSalaryRecordsTable)
    .where(and(...recConditions))
    .groupBy(employeeSalaryRecordsTable.employeeId);

  const advanceTotals = await db
    .select({
      employeeId: employeeAdvancesTable.employeeId,
      totalAdvances: sql<string>`coalesce(sum(${employeeAdvancesTable.amount}), 0)`,
    })
    .from(employeeAdvancesTable)
    .where(and(...advConditions))
    .groupBy(employeeAdvancesTable.employeeId);

  const salaryByEmployee = new Map(salaryTotals.map((t) => [t.employeeId, t]));
  const advanceByEmployee = new Map(advanceTotals.map((t) => [t.employeeId, t]));

  const summary = employees.map((op) => {
    const opRecords = records.filter((r) => r.employeeId === op.id);
    const opAdvances = advances.filter((a) => a.employeeId === op.id);
    const salaryTotal = salaryByEmployee.get(op.id);
    const advanceTotal = advanceByEmployee.get(op.id);
    const totalSalary = Number(salaryTotal?.totalSalary ?? 0);
    const totalAdvances = Number(advanceTotal?.totalAdvances ?? 0);
    const totalDaysWorked = salaryTotal?.totalDaysWorked ?? 0;
    const netPayable = totalSalary - totalAdvances;
    return {
      employeeId: op.id,
      employeeName: op.name,
      employeeCode: op.code,
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
