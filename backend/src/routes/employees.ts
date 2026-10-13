import { Router, type IRouter } from "express";
import { eq, and, gte, lte, lt, inArray } from "drizzle-orm";
import { db } from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";
import { loanBalances } from "../lib/loan-balance.js";
import { buildLoanLedger } from "../lib/loan-ledger.js";
import {
  employeeMasterTable,
  salaryDetailTable,
  employeeAdvancesTable,
  employeeLoansTable,
  employeeLoanDeductionsTable,
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

function toNum(val: unknown): number {
  const n = parseFloat(String(val ?? ""));
  return isNaN(n) ? 0 : n;
}

function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

function fmtMoney(n: number): string {
  return n.toLocaleString("en-PK", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
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

// ─── Loans ─────────────────────────────────────────────────────────────────
// A loan is a single running balance per employee (see lib/loan-balance.ts):
//   remaining = Σ(loans given) − Σ(posted payroll deductions)
// These routes mirror the Advances endpoints. The "money given" rows live
// here; the payroll recovery side is written by the salary Post handler.

/** Flat list of loan rows (all-time), optionally filtered to one employee. */
router.get("/employees/loans", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const { employeeId } = req.query as Record<string, string>;
  const conditions = [eq(employeeLoansTable.tenantId, tenantId)];
  if (employeeId) conditions.push(eq(employeeLoansTable.employeeId, Number(employeeId)));

  const rows = await db
    .select({
      id: employeeLoansTable.id,
      employeeId: employeeLoansTable.employeeId,
      employeeName: employeeMasterTable.name,
      date: employeeLoansTable.date,
      amount: employeeLoansTable.amount,
      notes: employeeLoansTable.notes,
      createdAt: employeeLoansTable.createdAt,
    })
    .from(employeeLoansTable)
    .leftJoin(employeeMasterTable, eq(employeeLoansTable.employeeId, employeeMasterTable.id))
    .where(and(...conditions))
    .orderBy(employeeLoansTable.date, employeeLoansTable.id);
  res.json(rows);
});

/** Per-employee totals (given / recovered / remaining) + grand totals. */
router.get("/employees/loans/summary", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);

  const loans = await db
    .select({ employeeId: employeeLoansTable.employeeId, amount: employeeLoansTable.amount })
    .from(employeeLoansTable)
    .where(eq(employeeLoansTable.tenantId, tenantId));
  const deductions = await db
    .select({ employeeId: employeeLoanDeductionsTable.employeeId, amount: employeeLoanDeductionsTable.amount })
    .from(employeeLoanDeductionsTable)
    .where(eq(employeeLoanDeductionsTable.tenantId, tenantId));

  const byEmployee = new Map<number, { totalLoaned: number; totalRecovered: number }>();
  const touch = (id: number) => {
    let e = byEmployee.get(id);
    if (!e) { e = { totalLoaned: 0, totalRecovered: 0 }; byEmployee.set(id, e); }
    return e;
  };
  for (const l of loans) touch(l.employeeId).totalLoaned += toNum(l.amount);
  for (const d of deductions) touch(d.employeeId).totalRecovered += toNum(d.amount);

  const employeeIds = [...byEmployee.keys()];
  const people = employeeIds.length
    ? await db
        .select({ id: employeeMasterTable.id, name: employeeMasterTable.name, code: employeeMasterTable.code })
        .from(employeeMasterTable)
        .where(and(eq(employeeMasterTable.tenantId, tenantId), inArray(employeeMasterTable.id, employeeIds)))
    : [];
  const nameById = new Map(people.map((p) => [p.id, p]));

  const employees = employeeIds
    .map((id) => {
      const e = byEmployee.get(id)!;
      const totalLoaned = round2(e.totalLoaned);
      const totalRecovered = round2(e.totalRecovered);
      return {
        employeeId: id,
        employeeName: nameById.get(id)?.name ?? `Employee #${id}`,
        employeeCode: nameById.get(id)?.code ?? null,
        totalLoaned,
        totalRecovered,
        remaining: round2(totalLoaned - totalRecovered),
      };
    })
    .sort((a, b) => a.employeeName.localeCompare(b.employeeName));

  const totals = employees.reduce(
    (acc, e) => ({
      loaned: round2(acc.loaned + e.totalLoaned),
      recovered: round2(acc.recovered + e.totalRecovered),
      outstanding: round2(acc.outstanding + e.remaining),
    }),
    { loaned: 0, recovered: 0, outstanding: 0 },
  );

  res.json({ employees, totals });
});

/** All-time running ledger for one employee (loans + payroll deductions). */
router.get("/employees/loans/ledger", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const employeeId = Number((req.query as Record<string, string>).employeeId);
  if (!Number.isInteger(employeeId) || employeeId <= 0) {
    res.status(400).json({ error: "employeeId is required" });
    return;
  }

  const [employee] = await db
    .select({ id: employeeMasterTable.id, name: employeeMasterTable.name, code: employeeMasterTable.code })
    .from(employeeMasterTable)
    .where(and(eq(employeeMasterTable.id, employeeId), eq(employeeMasterTable.tenantId, tenantId)));
  if (!employee) { res.status(404).json({ error: "Employee not found" }); return; }

  const loans = await db
    .select({
      id: employeeLoansTable.id,
      date: employeeLoansTable.date,
      amount: employeeLoansTable.amount,
      notes: employeeLoansTable.notes,
      createdAt: employeeLoansTable.createdAt,
    })
    .from(employeeLoansTable)
    .where(and(eq(employeeLoansTable.tenantId, tenantId), eq(employeeLoansTable.employeeId, employeeId)));

  const deductions = await db
    .select({
      id: employeeLoanDeductionsTable.id,
      date: employeeLoanDeductionsTable.date,
      amount: employeeLoanDeductionsTable.amount,
      month: employeeLoanDeductionsTable.month,
      year: employeeLoanDeductionsTable.year,
      createdAt: employeeLoanDeductionsTable.createdAt,
    })
    .from(employeeLoanDeductionsTable)
    .where(and(eq(employeeLoanDeductionsTable.tenantId, tenantId), eq(employeeLoanDeductionsTable.employeeId, employeeId)));

  const { totalLoaned, totalRecovered, remaining, entries } = buildLoanLedger(loans, deductions);

  res.json({
    employeeId,
    employeeName: employee.name,
    employeeCode: employee.code,
    totalLoaned,
    totalRecovered,
    remaining,
    entries,
  });
});

/** Record a loan given to an employee. */
router.post("/employees/loans", async (req, res): Promise<void> => {
  const { employeeId, date, amount, notes } = req.body;
  if (!employeeId || !date || amount === undefined) {
    res.status(400).json({ error: "employeeId, date, and amount are required" });
    return;
  }
  const amt = toNumStrict(amount);
  if (amt === null) { res.status(400).json({ error: "amount must be a valid number" }); return; }
  if (amt <= 0) { res.status(400).json({ error: "amount must be greater than 0" }); return; }

  const [row] = await db
    .insert(employeeLoansTable)
    .values({
      employeeId: Number(employeeId),
      date,
      amount: String(amt),
      notes: notes || null,
      tenantId: activeTenantId(req),
    })
    .returning();
  res.status(201).json(row);
});

/**
 * Delete a loan row. Refused when posted payroll has already recovered
 * against it — otherwise the running balance would go negative.
 */
router.delete("/employees/loans/:id", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const id = idParam(req);
  if (!id) { res.status(400).json({ error: "Invalid id" }); return; }

  const [row] = await db
    .select()
    .from(employeeLoansTable)
    .where(and(eq(employeeLoansTable.id, id), eq(employeeLoansTable.tenantId, tenantId)));
  if (!row) { res.status(404).json({ error: "Not found" }); return; }

  const balances = await loanBalances(tenantId, [row.employeeId]);
  const remaining = balances.get(row.employeeId)?.remaining ?? 0;
  if (round2(remaining - toNum(row.amount)) < -0.005) {
    res.status(409).json({
      error: `Cannot delete: this loan is already drawn against by posted payroll (remaining ${fmtMoney(remaining)}).`,
    });
    return;
  }

  await db
    .delete(employeeLoansTable)
    .where(and(eq(employeeLoansTable.id, id), eq(employeeLoansTable.tenantId, tenantId)));
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
