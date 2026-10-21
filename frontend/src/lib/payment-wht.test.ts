import { test } from "node:test";
import assert from "node:assert/strict";
import {
  derivePayment,
  deriveRateFromTax,
  clampNetForBalance,
  maxNetForBalance,
  DEFAULT_WHT_RATE,
  round2,
} from "./payment-wht.js";

test("DEFAULT_WHT_RATE is 1%", () => {
  assert.equal(DEFAULT_WHT_RATE, 0.01);
});

test("deriveRateFromTax: 990 net + 10 tax → 1%", () => {
  assert.equal(deriveRateFromTax(990, 10), 0.01);
});

test("deriveRateFromTax: no tax → 0%", () => {
  assert.equal(deriveRateFromTax(990, 0), 0);
});

test("deriveRateFromTax: round-trips derivePayment at the default rate", () => {
  const d = derivePayment(990, DEFAULT_WHT_RATE);
  assert.equal(round2(deriveRateFromTax(990, d.tax) * 100), 1);
});

test("deriveRateFromTax: invalid or zero inputs return 0, never NaN/Infinity", () => {
  assert.equal(deriveRateFromTax(0, 0), 0);
  assert.equal(deriveRateFromTax(NaN, 10), 0);
  assert.equal(deriveRateFromTax(100, NaN), 0);
  assert.equal(deriveRateFromTax(-10, 5), 0);
  // net 0 with tax > 0 would be rate 100% — clamp just below 1.
  assert.ok(deriveRateFromTax(0, 10) < 1);
});

test("clampNetForBalance: raising the rate pulls a maxed-out net down", () => {
  // 10,000 balance; net pre-filled at 1% max (9,900). At 2% the max net is 9,800.
  assert.equal(clampNetForBalance(9900, 10000, 0.02), 9800);
});

test("clampNetForBalance: a partial net below the maximum is untouched", () => {
  assert.equal(clampNetForBalance(5000, 10000, 0.02), 5000);
});

test("clampNetForBalance: lowering the rate does not change the net", () => {
  assert.equal(clampNetForBalance(9800, 10000, 0.01), 9800);
});

test("clampNetForBalance: zero balance or invalid input yields 0", () => {
  assert.equal(clampNetForBalance(5000, 0, 0.01), 0);
  assert.equal(clampNetForBalance(NaN, 10000, 0.01), 0);
  assert.equal(clampNetForBalance(5000, NaN, 0.01), 0);
});

test("derivePayment: 1% on gross — net 990 → gross 1000, tax 10 (requested example)", () => {
  const d = derivePayment(990, 0.01);
  assert.equal(d.tax, 10);
  assert.equal(d.gross, 1000);
  // net + tax always equals gross exactly
  assert.equal(round2(990 + d.tax), d.gross);
});

test("derivePayment: gross = net / (1 - rate) at the default rate", () => {
  const d = derivePayment(495, DEFAULT_WHT_RATE);
  assert.equal(d.gross, 500); // 495 / 0.99 = 500
  assert.equal(d.tax, 5);
});

test("derivePayment: zero net yields zero gross/tax", () => {
  const d = derivePayment(0, 0.01);
  assert.equal(d.tax, 0);
  assert.equal(d.gross, 0);
});

test("derivePayment: custom rate (2%) applies to gross", () => {
  const d = derivePayment(980, 0.02);
  // gross = 980 / 0.98 = 1000, tax = 20
  assert.equal(d.gross, 1000);
  assert.equal(d.tax, 20);
});

test("derivePayment: rate clamped to < 1 (never divide by zero)", () => {
  const d = derivePayment(100, 1); // invalid rate ≥ 1
  assert.ok(Number.isFinite(d.gross));
  assert.ok(Number.isFinite(d.tax));
});

test("derivePayment: rate 0 → no tax, gross = net", () => {
  const d = derivePayment(250, 0);
  assert.equal(d.tax, 0);
  assert.equal(d.gross, 250);
});

test("derivePayment: rounding keeps net + tax = gross (odd net)", () => {
  const d = derivePayment(999.99, DEFAULT_WHT_RATE);
  assert.equal(round2(999.99 + d.tax), d.gross);
});

test("maxNetForBalance: balance 10000 → max net 9900 at 1%", () => {
  assert.equal(maxNetForBalance(10000, DEFAULT_WHT_RATE), 9900);
});

test("maxNetForBalance: custom rate scales net", () => {
  assert.equal(maxNetForBalance(10000, 0.02), 9800);
});

test("maxNetForBalance: rate 0 → max net = balance", () => {
  assert.equal(maxNetForBalance(10000, 0), 10000);
});

test("maxNetForBalance: invalid rate clamped safely", () => {
  assert.ok(Number.isFinite(maxNetForBalance(10000, 1)));
});
