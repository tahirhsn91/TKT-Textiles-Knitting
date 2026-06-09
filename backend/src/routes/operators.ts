import { Router, type IRouter } from "express";
import { eq, and, gte, lte } from "drizzle-orm";
import { db } from "../db/index.js";
import {
  machineOperatorMasterTable,
  operatorSalarySettingsTable,
  operatorSalaryRecordsTable,
  operatorAdvancesTable,
} from "../db/index.js";

const router: IRouter = Router();

function idParam(req: { params: Record<string, string> }) {
  const id = parseInt(req.params.id);
  return isNaN(id) ? null : id;
}

function toNum(val: unknown): number {
  const n = parseFloat(String(val ?? ""));
  return isNaN(n) ? 0 : n;
}

// ─── Salary Settings ─────────────────────────────────────────────────────────

router.get("/operators/salary-settings", async (_req, res): Promise<void> => {
  const rows = await db
    .select({
      operatorId: machineOperatorMasterTable.id,
      operatorName: machineOperatorMasterTable.name,
      operatorCode: machineOperatorMasterTable.code,
      baseDailyWage: operatorSalarySettingsTable.baseDailyWage,
    })
    .from(machineOperatorMasterTable)
    .leftJoin(
      operatorSalarySettingsTable,
      eq(machineOperatorMasterTable.id, operatorSalarySettingsTable.operatorId)
    )
    .orderBy(machineOperatorMasterTable.name);
  res.json(rows);
});

router.post("/operators/salary-settings", async (req, res): Promise<void> => {
  const { operatorId, baseDailyWage } = req.body;
  if (!operatorId) { res.status(400).json({ error: "operatorId is required" }); return; }
  const wage = toNum(baseDailyWage);
  if (wage < 0) { res.status(400).json({ error: "baseDailyWage must be >= 0" }); return; }
  await db
    .insert(operatorSalarySettingsTable)
    .values({ operatorId: Number(operatorId), baseDailyWage: String(wage) })
    .onConflictDoUpdate({
      target: operatorSalarySettingsTable.operatorId,
      set: { baseDailyWage: String(wage) },
    });
  const [row] = await db
    .select({
      operatorId: machineOperatorMasterTable.id,
      operatorName: machineOperatorMasterTable.name,
      operatorCode: machineOperatorMasterTable.code,
      baseDailyWage: operatorSalarySettingsTable.baseDailyWage,
    })
    .from(machineOperatorMasterTable)
    .leftJoin(operatorSalarySettingsTable, eq(machineOperatorMasterTable.id, operatorSalarySettingsTable.operatorId))
    .where(eq(machineOperatorMasterTable.id, Number(operatorId)));
  res.json(row);
});

// ─── Salary Records ──────────────────────────────────────────────────────────

router.get("/operators/salary-records", async (req, res): Promise<void> => {
  const { operatorId, month, year } = req.query as Record<string, string>;
  if (!operatorId || !month || !year) {
    res.status(400).json({ error: "operatorId, month, and year are required" });
    return;
  }
  const m = parseInt(month);
  const y = parseInt(year);
  const dateFrom = `${y}-${String(m).padStart(2, "0")}-01`;
  const lastDay = new Date(y, m, 0).getDate();
  const dateTo = `${y}-${String(m).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
  const rows = await db
    .select()
    .from(operatorSalaryRecordsTable)
    .where(
      and(
        eq(operatorSalaryRecordsTable.operatorId, Number(operatorId)),
        gte(operatorSalaryRecordsTable.date, dateFrom),
        lte(operatorSalaryRecordsTable.date, dateTo)
      )
    )
    .orderBy(operatorSalaryRecordsTable.date);
  res.json(rows);
});

router.post("/operators/salary-records/bulk", async (req, res): Promise<void> => {
  const entries: { operatorId: number; date: string; commission: number }[] = req.body;
  if (!Array.isArray(entries) || entries.length === 0) {
    res.status(400).json({ error: "Body must be a non-empty array" });
    return;
  }
  for (const e of entries) {
    if (toNum(e.commission) < 0) {
      res.status(400).json({ error: "commission must be >= 0" });
      return;
    }
  }
  const results = [];
  for (const entry of entries) {
    const opId = Number(entry.operatorId);
    const commission = toNum(entry.commission);
    const [settings] = await db
      .select({ baseDailyWage: operatorSalarySettingsTable.baseDailyWage })
      .from(operatorSalarySettingsTable)
      .where(eq(operatorSalarySettingsTable.operatorId, opId));
    const baseWage = toNum(settings?.baseDailyWage);
    const finalSalary = Math.max(baseWage, commission);
    const [row] = await db
      .insert(operatorSalaryRecordsTable)
      .values({
        operatorId: opId,
        date: entry.date,
        baseWage: String(baseWage),
        commission: String(commission),
        finalSalary: String(finalSalary),
      })
      .onConflictDoUpdate({
        target: [operatorSalaryRecordsTable.operatorId, operatorSalaryRecordsTable.date],
        set: {
          baseWage: String(baseWage),
          commission: String(commission),
          finalSalary: String(finalSalary),
        },
      })
      .returning();
    results.push(row);
  }
  res.json(results);
});

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
  const amt = toNum(amount);
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

  const summary = operators.map((op) => {
    const opRecords = records.filter((r) => r.operatorId === op.id);
    const opAdvances = advances.filter((a) => a.operatorId === op.id);
    const totalDaysWorked = opRecords.length;
    const totalSalary = opRecords.reduce((sum, r) => sum + toNum(r.finalSalary), 0);
    const totalAdvances = opAdvances.reduce((sum, a) => sum + toNum(a.amount), 0);
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
