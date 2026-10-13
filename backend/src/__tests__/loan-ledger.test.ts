import { test } from "node:test";
import assert from "node:assert/strict";
import { buildLoanLedger } from "../lib/loan-ledger.js";

test("buildLoanLedger: a loan then its payroll deduction produce a running balance", () => {
  const ledger = buildLoanLedger(
    [{ id: 1, date: "2026-01-05", amount: "50000", notes: "Initial loan", createdAt: "2026-01-05T10:00:00Z" }],
    [{ id: 1, date: "2026-01-31", amount: "5000", month: 1, year: 2026, createdAt: "2026-02-01T09:00:00Z" }],
  );

  assert.equal(ledger.totalLoaned, 50000);
  assert.equal(ledger.totalRecovered, 5000);
  assert.equal(ledger.remaining, 45000);

  assert.equal(ledger.entries.length, 2);
  assert.equal(ledger.entries[0].type, "loan");
  assert.equal(ledger.entries[0].balance, 50000);
  assert.equal(ledger.entries[1].type, "deduction");
  assert.equal(ledger.entries[1].amount, 5000);
  assert.equal(ledger.entries[1].balance, 45000);
  assert.equal(ledger.entries[1].period, "2026-01");
});

test("buildLoanLedger: multiple loans and multiple deductions net correctly", () => {
  const ledger = buildLoanLedger(
    [
      { id: 1, date: "2026-01-01", amount: "20000" },
      { id: 2, date: "2026-02-01", amount: "10000", notes: "Top-up" },
    ],
    [
      { id: 1, date: "2026-01-31", amount: "3000", month: 1, year: 2026 },
      { id: 2, date: "2026-02-28", amount: "4000", month: 2, year: 2026 },
      { id: 3, date: "2026-03-31", amount: "5000", month: 3, year: 2026 },
    ],
  );

  assert.equal(ledger.totalLoaned, 30000);
  assert.equal(ledger.totalRecovered, 12000);
  assert.equal(ledger.remaining, 18000);
  assert.equal(ledger.entries.length, 5);
  // Running balance walks: +20000, −3000, +10000, −4000, −5000.
  assert.deepEqual(
    ledger.entries.map((e) => e.balance),
    [20000, 17000, 27000, 23000, 18000],
  );
});

test("buildLoanLedger: entries are ordered by date, ties by creation then id", () => {
  const ledger = buildLoanLedger(
    [{ id: 2, date: "2026-01-10", amount: "1000", createdAt: "2026-01-10T12:00:00Z" }],
    [
      { id: 9, date: "2026-01-10", amount: "100", month: 1, year: 2026, createdAt: "2026-01-10T08:00:00Z" },
      { id: 3, date: "2026-01-10", amount: "200", month: 1, year: 2026, createdAt: "2026-01-10T09:00:00Z" },
    ],
  );

  // Same date: earlier createdAt first (deduction 9, deduction 3), then the
  // loan (created later).
  assert.deepEqual(
    ledger.entries.map((e) => e.id),
    ["deduction-9", "deduction-3", "loan-2"],
  );
  assert.deepEqual(
    ledger.entries.map((e) => e.balance),
    [-100, -300, 700],
  );
});

test("buildLoanLedger: empty history is all zeroes", () => {
  const ledger = buildLoanLedger([], []);
  assert.equal(ledger.totalLoaned, 0);
  assert.equal(ledger.totalRecovered, 0);
  assert.equal(ledger.remaining, 0);
  assert.deepEqual(ledger.entries, []);
});

test("buildLoanLedger: invalid amounts read as zero, never NaN", () => {
  const ledger = buildLoanLedger([{ id: 1, date: "2026-01-01", amount: "" }], []);
  assert.equal(ledger.totalLoaned, 0);
  assert.equal(ledger.remaining, 0);
  assert.equal(ledger.entries[0].amount, 0);
});
