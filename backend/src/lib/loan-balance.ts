import { and, eq, inArray, ne } from "drizzle-orm";
import { db } from "../db/index.js";
import { employeeLoansTable, employeeLoanDeductionsTable } from "../db/index.js";

/**
 * A loan is a single running balance per employee:
 *   remaining = Σ(loans given) − Σ(posted payroll deductions)
 *
 * Deduction rows are written only when a salary entry is posted (and removed
 * when it is un-posted), so drafts never move the balance. "Remaining" can
 * never go below zero — the post handler refuses a deduction that would
 * over-recover, and deleting a loan already drawn against is rejected.
 */
export interface LoanBalance {
  employeeId: number;
  totalLoaned: number;
  totalRecovered: number;
  remaining: number;
}

function num(val: unknown): number {
  const n = parseFloat(String(val ?? ""));
  return isNaN(n) ? 0 : n;
}

function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

/**
 * Remaining loan balance for each of `employeeIds`.
 *
 * `excludeHeaderId` skips one salary header's deductions. The post handler
 * validates against the balance *before* that header's own deduction rows are
 * written, so its not-yet-committed amount must not count against itself.
 */
export async function loanBalances(
  tenantId: number,
  employeeIds: number[],
  excludeHeaderId?: number,
): Promise<Map<number, LoanBalance>> {
  const balances = new Map<number, LoanBalance>();
  for (const id of employeeIds) {
    balances.set(id, { employeeId: id, totalLoaned: 0, totalRecovered: 0, remaining: 0 });
  }
  if (employeeIds.length === 0) return balances;

  const loans = await db
    .select({ employeeId: employeeLoansTable.employeeId, amount: employeeLoansTable.amount })
    .from(employeeLoansTable)
    .where(
      and(eq(employeeLoansTable.tenantId, tenantId), inArray(employeeLoansTable.employeeId, employeeIds)),
    );
  for (const l of loans) {
    const b = balances.get(l.employeeId);
    if (b) b.totalLoaned += num(l.amount);
  }

  const deductionConditions = [
    eq(employeeLoanDeductionsTable.tenantId, tenantId),
    inArray(employeeLoanDeductionsTable.employeeId, employeeIds),
  ];
  if (excludeHeaderId !== undefined) {
    deductionConditions.push(ne(employeeLoanDeductionsTable.headerId, excludeHeaderId));
  }
  const deductions = await db
    .select({ employeeId: employeeLoanDeductionsTable.employeeId, amount: employeeLoanDeductionsTable.amount })
    .from(employeeLoanDeductionsTable)
    .where(and(...deductionConditions));
  for (const d of deductions) {
    const b = balances.get(d.employeeId);
    if (b) b.totalRecovered += num(d.amount);
  }

  for (const b of balances.values()) {
    b.totalLoaned = round2(b.totalLoaned);
    b.totalRecovered = round2(b.totalRecovered);
    b.remaining = round2(b.totalLoaned - b.totalRecovered);
  }
  return balances;
}
