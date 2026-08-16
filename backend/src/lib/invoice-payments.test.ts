import { test } from "node:test";
import assert from "node:assert/strict";
import {
  computePaymentState,
  paymentNetApplied,
  sumNetApplied,
  addDays,
  daysBetween,
} from "./invoice-payments.js";

// Anchored to the real clock so due/overdue assertions hold regardless of when
// the suite runs.
function daysFromNowIso(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${dd}`;
}

test("paymentNetApplied: amount minus tax deduction", () => {
  assert.equal(paymentNetApplied({ amount: "100", taxDeduction: "1" }), 99);
  assert.equal(paymentNetApplied({ amount: "100", taxDeduction: "0" }), 100);
});

test("sumNetApplied: sums net amounts across payments", () => {
  const payments = [
    { amount: "100", taxDeduction: "1" },
    { amount: "50", taxDeduction: "0.5" },
  ];
  assert.equal(sumNetApplied(payments), 148.5);
});

test("computePaymentState: untracked (dueDays 0/null) never overdue", () => {
  const s = computePaymentState({
    grandTotal: "1000",
    dueDays: 0,
    postedDateIso: daysFromNowIso(-10),
    payments: [{ amount: "200", taxDeduction: "0" }],
  });
  assert.equal(s.dueDateIso, null);
  assert.equal(s.overdue, false);
  assert.equal(s.paid, false);
  assert.equal(s.outstanding, 800);
});

test("computePaymentState: tracked, not yet due", () => {
  // Posted 40 days ago with 60 days credit → due in +20 days (future).
  const s = computePaymentState({
    grandTotal: "1000",
    dueDays: 60,
    postedDateIso: daysFromNowIso(-40),
    payments: [{ amount: "200", taxDeduction: "0" }],
  });
  assert.equal(s.overdue, false);
  assert.notEqual(s.dueDateIso, null);
});

test("computePaymentState: tracked, overdue", () => {
  // Posted 40 days ago with 10 days credit → overdue by ~30 days.
  const s = computePaymentState({
    grandTotal: "1000",
    dueDays: 10,
    postedDateIso: daysFromNowIso(-40),
    payments: [{ amount: "200", taxDeduction: "0" }],
  });
  assert.equal(s.overdue, true);
});

test("computePaymentState: paid via net applied", () => {
  const s = computePaymentState({
    grandTotal: "1000",
    dueDays: 30,
    postedDateIso: daysFromNowIso(-40),
    payments: [{ amount: "1000", taxDeduction: "10" }], // net 990 < 1000
  });
  assert.equal(s.paid, false);
  assert.equal(s.outstanding, 10);
});

test("computePaymentState: overpaid shows surplus", () => {
  const s = computePaymentState({
    grandTotal: "1000",
    dueDays: 30,
    postedDateIso: daysFromNowIso(-40),
    payments: [{ amount: "1100", taxDeduction: "0" }],
  });
  assert.equal(s.paid, true);
  assert.equal(s.overpaid, 100);
  assert.equal(s.outstanding, -100);
});

test("computePaymentState: WHT total reported", () => {
  const s = computePaymentState({
    grandTotal: "1000",
    dueDays: 0,
    postedDateIso: daysFromNowIso(-10),
    payments: [
      { amount: "100", taxDeduction: "1" },
      { amount: "200", taxDeduction: "2" },
    ],
  });
  assert.equal(s.totalTaxDeduction, 3);
});

test("addDays: calendar days from ISO date", () => {
  assert.equal(addDays("2026-01-31", 30), "2026-03-02"); // Jan 31 + 30
  assert.equal(addDays("2026-08-14", 30), "2026-09-13");
});

test("daysBetween: positive when past", () => {
  assert.equal(daysBetween("2026-03-05", "2026-02-03"), 30);
  assert.equal(daysBetween("2026-02-03", "2026-03-05"), -30);
});
