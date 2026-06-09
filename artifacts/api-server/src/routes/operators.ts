import { Router, type IRouter } from "express";
import { eq, and, sql } from "drizzle-orm";
import { db } from "@workspace/db";
import {
  machineOperatorMasterTable,
  operatorSalarySettingsTable,
  operatorSalaryRecordsTable,
  operatorAdvancesTable,
} from "@workspace/db";

const router: IRouter = Router();

function idParam(req: { params: Record<string, string> }) {
  const id = parseInt(req.params.id);
  return isNaN(id) ? null : id;
}

// ─── Salary Settings ────────────────────────────────────────────────────────

router.get("/operators/salary-settings", async (_req, res): Promise<void> => {
  const rows = await db
    .select({
      id: operatorSalarySettingsTable.id,
      operatorId: operatorSalarySettingsTable.operatorId,
      baseDailyWage: operatorSalarySettingsTable.baseDailyWage,
      operatorName: machineOperatorMasterTable.name,
      operatorCode: machineOperatorMasterTable.code,
    })
    .from(operatorSalarySettingsTable)
    .leftJoin(machineOperatorMasterTable, eq(operatorSalarySettingsTable.operatorId, machineOperatorMasterTable.id))
    .orderBy(machineOperatorMasterTable.name);
  res.json(rows);
});

router.post("/operators/salary-settings", async (req, res): Promise<void> => {
  const { operatorId, baseDailyWage } = req.body;
  if (!operatorId || baseDailyWage === undefined) {
    res.status(400).json({ error: "operatorId and baseDailyWage are required" });
    return;
  }
  const opId = parseInt(operatorId);
  const existing = await db
    .select()
    .from(operatorSalarySettingsTable)
    .where(eq(operatorSalarySettingsTable.operatorId, opId))
    .limit(1);

  if (existing.length > 0) {
    const [row] = await db
      .update(operatorSalarySettingsTable)
      .set({ baseDailyWage: String(baseDailyWage) })
      .where(eq(operatorSalarySettingsTable.operatorId, opId))
      .returning();
    res.json(row);
  } else {
    const [row] = await db
      .insert(operatorSalarySettingsTable)
      .values({ operatorId: opId, baseDailyWage: String(baseDailyWage) })
      .returning();
    res.status(201).json(row);
  }
});

// ─── Salary Records ──────────────────────────────────────────────────────────

router.get("/operators/salary-records", async (req, res): Promise<void> => {
  const { operatorId, month, year } = req.query as Record<string, string>;
  if (!operatorId || !month || !year) {
    res.status(400).json({ error: "operatorId, month and year are required" });
    return;
  }
  const opId = parseInt(operatorId);
  const m = month.padStart(2, "0");
  const prefix = `${year}-${m}-`;
  const rows = await db
    .select()
    .from(operatorSalaryRecordsTable)
    .where(
      and(
        eq(operatorSalaryRecordsTable.operatorId, opId),
        sql`${operatorSalaryRecordsTable.date} LIKE ${prefix + "%"}`
      )
    )
    .orderBy(operatorSalaryRecordsTable.date);
  res.json(rows);
});

router.post("/operators/salary-records/bulk", async (req, res): Promise<void> => {
  const { operatorId, records } = req.body as {
    operatorId: number;
    records: Array<{ date: string; baseWage: string; commission: string; finalSalary: string }>;
  };
  if (!operatorId || !Array.isArray(records)) {
    res.status(400).json({ error: "operatorId and records are required" });
    return;
  }
  if (records.length === 0) {
    res.json([]);
    return;
  }
  const values = records.map((r) => ({
    operatorId,
    date: r.date,
    baseWage: r.baseWage,
    commission: r.commission,
    finalSalary: r.finalSalary,
  }));
  const rows = await db
    .insert(operatorSalaryRecordsTable)
    .values(values)
    .onConflictDoUpdate({
      target: [operatorSalaryRecordsTable.operatorId, operatorSalaryRecordsTable.date],
      set: {
        baseWage: sql`excluded.base_wage`,
        commission: sql`excluded.commission`,
        finalSalary: sql`excluded.final_salary`,
      },
    })
    .returning();
  res.json(rows);
});

// ─── Advances ────────────────────────────────────────────────────────────────

router.get("/operators/advances", async (req, res): Promise<void> => {
  const { operatorId, month, year } = req.query as Record<string, string>;
  if (!operatorId) {
    res.status(400).json({ error: "operatorId is required" });
    return;
  }
  const opId = parseInt(operatorId);
  const conditions = [eq(operatorAdvancesTable.operatorId, opId)];
  if (month && year) {
    const m = month.padStart(2, "0");
    const prefix = `${year}-${m}-`;
    conditions.push(sql`${operatorAdvancesTable.date} LIKE ${prefix + "%"}`);
  }
  const rows = await db
    .select()
    .from(operatorAdvancesTable)
    .where(and(...conditions))
    .orderBy(operatorAdvancesTable.date);
  res.json(rows);
});

router.post("/operators/advances", async (req, res): Promise<void> => {
  const { operatorId, date, amount, notes } = req.body;
  if (!operatorId || !date || amount === undefined) {
    res.status(400).json({ error: "operatorId, date and amount are required" });
    return;
  }
  const [row] = await db
    .insert(operatorAdvancesTable)
    .values({ operatorId: parseInt(operatorId), date, amount: String(amount), notes: notes || null })
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
  const m = month.padStart(2, "0");
  const prefix = `${year}-${m}-%`;

  const opFilter = operatorId ? `AND op.id = ${parseInt(operatorId)}` : "";

  const result = await db.execute(sql`
    SELECT
      op.id           AS "operatorId",
      op.name         AS "operatorName",
      op.code         AS "operatorCode",
      COALESCE(sr."daysRecorded", 0)    AS "daysRecorded",
      COALESCE(sr."totalBaseWage", 0)   AS "totalBaseWage",
      COALESCE(sr."totalCommission", 0) AS "totalCommission",
      COALESCE(sr."totalSalary", 0)     AS "totalSalary",
      COALESCE(adv."totalAdvances", 0)  AS "totalAdvances",
      COALESCE(sr."totalSalary", 0) - COALESCE(adv."totalAdvances", 0) AS "netPayable",
      COALESCE(ss.base_daily_wage, 0)   AS "baseDailyWage"
    FROM machine_operator_master op
    LEFT JOIN (
      SELECT
        operator_id,
        COUNT(*)        AS "daysRecorded",
        SUM(base_wage)  AS "totalBaseWage",
        SUM(commission) AS "totalCommission",
        SUM(final_salary) AS "totalSalary"
      FROM operator_salary_records
      WHERE date LIKE ${prefix}
      GROUP BY operator_id
    ) sr ON sr.operator_id = op.id
    LEFT JOIN (
      SELECT
        operator_id,
        SUM(amount) AS "totalAdvances"
      FROM operator_advances
      WHERE date LIKE ${prefix}
      GROUP BY operator_id
    ) adv ON adv.operator_id = op.id
    LEFT JOIN operator_salary_settings ss ON ss.operator_id = op.id
    WHERE (sr.operator_id IS NOT NULL OR adv.operator_id IS NOT NULL OR TRUE)
    ${sql.raw(opFilter)}
    ORDER BY op.name
  `);

  res.json(result.rows);
});

export default router;
