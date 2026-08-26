import { Router, type IRouter } from "express";
import { eq, and, inArray, gte, lte } from "drizzle-orm";
import { db } from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";
import {
  attendanceTable,
  employeeMasterTable,
  departmentMasterTable,
  salaryDetailTable,
  transactionHeaderTable,
  transactionDetailTable,
  transactionTypeMasterTable,
} from "../db/index.js";

const router: IRouter = Router();

function toNum(val: unknown): number {
  const n = parseFloat(String(val ?? ""));
  return isNaN(n) ? 0 : n;
}

// Inclusive first day of a month, e.g. "2026-08-01".
function monthStart(year: number, month: number): string {
  return `${year}-${String(month).padStart(2, "0")}-01`;
}
// Inclusive last day of a month, e.g. "2026-08-31".
function monthEnd(year: number, month: number): string {
  const lastDay = new Date(year, month, 0).getDate();
  return `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;
}
// Number of days in a month.
function daysInMonth(year: number, month: number): number {
  return new Date(year, month, 0).getDate();
}

// Whether ANY payroll salary detail exists for the given month+year. Used to
// (a) lock attendance editing once a payroll entry exists for the month, and
// (b) flag the payroll gate from the attendance side.
async function payrollExistsForMonth(month: number, year: number, tenantId: number): Promise<boolean> {
  const rows = await db
    .select({ id: salaryDetailTable.id })
    .from(salaryDetailTable)
    .where(and(eq(salaryDetailTable.month, month), eq(salaryDetailTable.year, year), eq(salaryDetailTable.tenantId, tenantId)))
    .limit(1);
  return rows.length > 0;
}

// The Operator department (code 0002). Operators are paid on production in
// payroll; this attendance endpoint just needs to know who they are so the
// frontend can decide Sunday auto-check (non-operators only).
async function operatorDeptId(tenantId: number): Promise<number | null> {
  const [dept] = await db
    .select({ id: departmentMasterTable.id })
    .from(departmentMasterTable)
    .where(and(eq(departmentMasterTable.code, "0002"), eq(departmentMasterTable.tenantId, tenantId)));
  return dept?.id ?? null;
}

// Distinct calendar dates in [dateFrom, dateTo] on which each Operator (dept
// 0002) has >=1 Fabric Production transaction detail row with net weight > 0.
// Same definition the operator-production salary endpoint uses, so the
// attendance grid marks exactly the same days as "produced" (auto-present for
// operators). Returns employeeId -> sorted date list.
async function operatorProductionDays(
  dateFrom: string,
  dateTo: string,
  tenantId: number
): Promise<Map<number, string[]>> {
  const [fabricProd, operatorDept] = await Promise.all([
    db
      .select({ id: transactionTypeMasterTable.id })
      .from(transactionTypeMasterTable)
      .where(and(eq(transactionTypeMasterTable.code, "Fabric_Production"), eq(transactionTypeMasterTable.tenantId, tenantId)))
      .limit(1),
    db
      .select({ id: departmentMasterTable.id })
      .from(departmentMasterTable)
      .where(and(eq(departmentMasterTable.code, "0002"), eq(departmentMasterTable.tenantId, tenantId)))
      .limit(1),
  ]);
  if (!fabricProd[0] || !operatorDept[0]) return new Map();

  const headers = await db
    .select({ id: transactionHeaderTable.id, date: transactionHeaderTable.date })
    .from(transactionHeaderTable)
    .where(
      and(
        eq(transactionHeaderTable.transactionTypeId, fabricProd[0].id),
        gte(transactionHeaderTable.date, dateFrom),
        lte(transactionHeaderTable.date, dateTo),
        eq(transactionHeaderTable.tenantId, tenantId),
      )
    );
  const headerIds = headers.map((h) => h.id);
  const dateById = new Map(headers.map((h) => [h.id, h.date]));
  if (headerIds.length === 0) return new Map();

  const details = await db
    .select({ employeeId: transactionDetailTable.employeeId, headerId: transactionDetailTable.headerId, netWt: transactionDetailTable.netWt })
    .from(transactionDetailTable)
    .where(and(inArray(transactionDetailTable.headerId, headerIds), eq(transactionDetailTable.tenantId, tenantId)));

  const byEmp = new Map<number, Set<string>>();
  for (const d of details) {
    if (!d.employeeId || toNum(d.netWt) <= 0) continue;
    const date = dateById.get(d.headerId);
    if (!date) continue;
    let set = byEmp.get(d.employeeId);
    if (!set) { set = new Set(); byEmp.set(d.employeeId, set); }
    set.add(date);
  }
  const out = new Map<number, string[]>();
  for (const [empId, set] of byEmp) {
    out.set(empId, [...set].sort());
  }
  return out;
}

// ─── Get attendance for a month ────────────────────────────────────────────
// Returns the attendance rows for the month plus the active employees (so the
// grid can render employee rows and pre-check Sundays for non-operators only)
// and whether a payroll entry already exists for that month (which locks
// editing).
router.get("/", async (req, res): Promise<void> => {
  const { month, year } = req.query as Record<string, string>;
  if (!month || !year) {
    res.status(400).json({ error: "month and year are required" });
    return;
  }
  const m = parseInt(month);
  const y = parseInt(year);
  if (isNaN(m) || isNaN(y)) {
    res.status(400).json({ error: "month and year must be numbers" });
    return;
  }

  const from = monthStart(y, m);
  const to = monthEnd(y, m);
  const tenantId = activeTenantId(req);

  const [records, deptId, payrollExists, productionDays] = await Promise.all([
    db
      .select()
      .from(attendanceTable)
      .where(and(gte(attendanceTable.attendanceDate, from), lte(attendanceTable.attendanceDate, to), eq(attendanceTable.tenantId, tenantId))),
    operatorDeptId(tenantId),
    payrollExistsForMonth(m, y, tenantId),
    operatorProductionDays(from, to, tenantId),
  ]);

  res.json({
    month: m,
    year: y,
    daysInMonth: daysInMonth(y, m),
    operatorDepartmentId: deptId,
    payrollExists: payrollExists,
    // Operator production-days (distinct transaction dates), used by the grid
    // to auto-mark operators Present and lock those cells.
    productionDaysByEmployee: Object.fromEntries(productionDays),
    records: records.map((r) => ({
      employeeId: r.employeeId,
      attendanceDate: r.attendanceDate,
      present: r.present,
    })),
  });
});

// ─── Save (upsert) attendance for a month ──────────────────────────────────
// Replaces the month's attendance rows with the submitted set. Accepts an
// array of { employeeId, attendanceDate, present }. Idempotent upsert by
// (employee_id, attendance_date). Blocked with 409 if a payroll entry already
// exists for the month (attendance is locked once payroll exists — spec Q10B).
router.put("/", async (req, res): Promise<void> => {
  const { month, year, records } = req.body as {
    month: number;
    year: number;
    records: Array<{ employeeId: number; attendanceDate: string; present: boolean }>;
  };

  if (!month || !year || !Array.isArray(records)) {
    res.status(400).json({ error: "month, year, and records are required" });
    return;
  }
  const m = parseInt(String(month));
  const y = parseInt(String(year));
  if (isNaN(m) || isNaN(y)) {
    res.status(400).json({ error: "month and year must be numbers" });
    return;
  }
  // Do not allow saving attendance for a future month (spec Q9A: future months
  // not selectable).
  const now = new Date();
  if (y > now.getFullYear() || (y === now.getFullYear() && m > now.getMonth() + 1)) {
    res.status(400).json({ error: "Cannot save attendance for a future month" });
    return;
  }

  // Lock: once a payroll entry exists for the month, attendance can't change.
  const tenantId = activeTenantId(req);
  const [payrollExists] = await Promise.all([payrollExistsForMonth(m, y, tenantId)]);
  if (payrollExists) {
    res.status(409).json({
      error: "Attendance for this month is locked because a payroll entry already exists.",
    });
    return;
  }

  // Validate: only active employees, no future dates within the month.
  const empIds = [...new Set(records.map((r) => r.employeeId))];
  const employees = empIds.length
    ? await db
        .select({ id: employeeMasterTable.id })
        .from(employeeMasterTable)
        .where(and(inArray(employeeMasterTable.id, empIds), eq(employeeMasterTable.tenantId, tenantId)))
    : [];
  const validIdSet = new Set(employees.map((e) => e.id));

  const from = monthStart(y, m);
  const to = monthEnd(y, m);
  const todayIso = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;

  const rows = records
    .filter((r) => validIdSet.has(r.employeeId))
    .filter((r) => r.attendanceDate >= from && r.attendanceDate <= to && r.attendanceDate <= todayIso)
    .map((r) => ({
      employeeId: r.employeeId,
      tenantId,
      attendanceDate: r.attendanceDate,
      present: Boolean(r.present),
    }));

  await db.transaction(async (tx) => {
    const touchedEmpIds = [...new Set(rows.map((r) => r.employeeId))];
    if (touchedEmpIds.length) {
      await tx
        .delete(attendanceTable)
        .where(
          and(
            inArray(attendanceTable.employeeId, touchedEmpIds),
            eq(attendanceTable.tenantId, tenantId),
            gte(attendanceTable.attendanceDate, from),
            lte(attendanceTable.attendanceDate, to)
          )
        );
    }
    if (rows.length) {
      await tx.insert(attendanceTable).values(rows).onConflictDoNothing();
    }
  });

  res.json({ saved: rows.length });
});

export default router;
