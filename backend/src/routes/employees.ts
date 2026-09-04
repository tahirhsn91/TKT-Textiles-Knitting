import { Router, type IRouter } from "express";
import { eq, and, gte, lte, lt } from "drizzle-orm";
import { db } from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";
import {
  employeeMasterTable,
  salaryDetailTable,
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
  const tenantId = activeTenantId(req);
  const { employeeId, dateFrom, dateTo, month, year } = req.query as Record<string, string>;
  const conditions = [eq(employeeAdvancesTable.tenantId, tenantId)];
  if (employeeId) conditions.push(eq(employeeAdvancesTable.employeeId, Number(employeeId)));
  if (dateFrom) conditions.push(gte(employeeAdvancesTable.date, dateFrom));
  if (dateTo) conditions.push(lte(employeeAdvancesTable.date, dateTo));
  if (year && month) {
    const y = Number(year);
    const m = Number(month);
    if (Number.isInteger(y) && y > 0 && Number.isInteger(m) && m >= 1 && m <= 12) {
      const start = `${y}-${String(m).padStart(2, "0")}-01`;
      const end = `${m === 12 ? y + 1 : y}-${String(m === 12 ? 1 : m + 1).padStart(2, "0")}-01`;
      conditions.push(gte(employeeAdvancesTable.date, start));
      conditions.push(lt(employeeAdvancesTable.date, end));
    }
  } else if (year) {
    const y = Number(year);
    if (Number.isInteger(y) && y > 0) {
      conditions.push(gte(employeeAdvancesTable.date, `${y}-01-01`));
      conditions.push(lt(employeeAdvancesTable.date, `${y + 1}-01-01`));
    }
  }

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
    .where(and(...conditions))
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
    .values({ employeeId: Number(employeeId), date, amount: String(amt), notes: notes || null, tenantId: activeTenantId(req) })
    .returning();
  res.status(201).json(row);
});

router.delete("/employees/advances/:id", async (req, res): Promise<void> => {
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }
  const [row] = await db
    .delete(employeeAdvancesTable)
    .where(and(eq(employeeAdvancesTable.id, id), eq(employeeAdvancesTable.tenantId, activeTenantId(req))))
    .returning();
  if (!row) { res.status(404).json({ error: "Not found" }); return; }
  res.sendStatus(204);
});

// ─── Payroll Summary ─────────────────────────────────────────────────────────

router.get("/employees/payroll-summary", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
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

  // Source of truth is the posted/monthly payroll entries: each employee with a
  // salary_detail row for this month/year. Days worked, gross salary and the
  // advance deduction all come straight from that entry, while the authoritative
  // net is the stored payable_salary (it already nets OT, attendance/holiday
  // bonus and loan/other deductions too — recomputing it as salary − advances
  // here would be wrong). The old implementation read the now-unused
  // employee_salary_records daily table, which is never written to by the
  // current payroll flow (Salary Entry → salary_detail), so it always returned
  // zero salaries. advances remain the dated advance rows for the month so the
  // UI/PDF can still break them out.
  const detailConditions = [
    eq(salaryDetailTable.month, m),
    eq(salaryDetailTable.year, y),
    eq(salaryDetailTable.tenantId, tenantId),
  ];
  const advConditions = [
    gte(employeeAdvancesTable.date, dateFrom),
    lte(employeeAdvancesTable.date, dateTo),
    eq(employeeAdvancesTable.tenantId, tenantId),
  ];

  if (employeeId) {
    detailConditions.push(eq(salaryDetailTable.employeeId, Number(employeeId)));
    advConditions.push(eq(employeeAdvancesTable.employeeId, Number(employeeId)));
  }

  const details = await db
    .select({
      employeeId: salaryDetailTable.employeeId,
      employeeName: employeeMasterTable.name,
      employeeCode: employeeMasterTable.code,
      presentDays: salaryDetailTable.presentDays,
      totalSalary: salaryDetailTable.totalSalary,
      advanceDeduction: salaryDetailTable.advanceDeduction,
      payableSalary: salaryDetailTable.payableSalary,
    })
    .from(salaryDetailTable)
    .innerJoin(employeeMasterTable, and(eq(salaryDetailTable.employeeId, employeeMasterTable.id), eq(employeeMasterTable.tenantId, tenantId)))
    .where(and(...detailConditions))
    .orderBy(employeeMasterTable.name);

  const advances = await db
    .select()
    .from(employeeAdvancesTable)
    .where(and(...advConditions));

  const summary = details.map((d) => {
    const opAdvances = advances.filter((a) => a.employeeId === d.employeeId);
    const totalSalary = Number(d.totalSalary);
    const totalAdvances = Number(d.advanceDeduction);
    const netPayable = Number(d.payableSalary);
    return {
      employeeId: d.employeeId,
      employeeName: d.employeeName,
      employeeCode: d.employeeCode,
      totalDaysWorked: Number(d.presentDays),
      totalSalary,
      totalAdvances,
      netPayable,
      advances: opAdvances,
    };
  });

  res.json(summary);
});

export default router;
