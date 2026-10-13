/**
 * Pure loan-ledger maths (no DB import, so it is unit-testable).
 *
 * A loan is a single running balance per employee:
 *   remaining = Σ(loans given) − Σ(posted payroll deductions)
 *
 * Entries are merged in date order (ties broken by creation order, then id)
 * and each carries the running `balance` after it.
 */

export interface LoanLedgerLoan {
  id: number;
  date: string;
  amount: string | number;
  notes?: string | null;
  createdAt?: Date | string | null;
}

export interface LoanLedgerDeduction {
  id: number;
  date: string;
  amount: string | number;
  month: number;
  year: number;
  createdAt?: Date | string | null;
}

export interface LoanLedgerEntry {
  id: string;
  type: "loan" | "deduction";
  date: string;
  amount: number;
  notes: string | null;
  period: string | null;
  balance: number;
}

export interface LoanLedger {
  totalLoaned: number;
  totalRecovered: number;
  remaining: number;
  entries: LoanLedgerEntry[];
}

function num(val: unknown): number {
  const n = parseFloat(String(val ?? ""));
  return isNaN(n) ? 0 : n;
}

export function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

export function buildLoanLedger(
  loans: LoanLedgerLoan[],
  deductions: LoanLedgerDeduction[],
): LoanLedger {
  const merged = [
    ...loans.map((l) => ({
      id: `loan-${l.id}`,
      type: "loan" as const,
      date: l.date,
      amount: num(l.amount),
      notes: l.notes ?? null,
      period: null as string | null,
      sortKey: String(l.createdAt ?? ""),
    })),
    ...deductions.map((d) => ({
      id: `deduction-${d.id}`,
      type: "deduction" as const,
      date: d.date,
      amount: num(d.amount),
      notes: null as string | null,
      period: `${d.year}-${String(d.month).padStart(2, "0")}`,
      sortKey: String(d.createdAt ?? ""),
    })),
  ].sort(
    (a, b) => a.date.localeCompare(b.date) || a.sortKey.localeCompare(b.sortKey) || a.id.localeCompare(b.id),
  );

  let running = 0;
  let totalLoaned = 0;
  let totalRecovered = 0;
  const entries: LoanLedgerEntry[] = merged.map((e) => {
    if (e.type === "loan") { running += e.amount; totalLoaned += e.amount; }
    else { running -= e.amount; totalRecovered += e.amount; }
    const { sortKey, ...rest } = e;
    return { ...rest, balance: round2(running) };
  });

  return {
    totalLoaned: round2(totalLoaned),
    totalRecovered: round2(totalRecovered),
    remaining: round2(totalLoaned - totalRecovered),
    entries,
  };
}
