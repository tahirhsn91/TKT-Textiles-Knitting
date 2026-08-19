import { test } from "node:test";
import assert from "node:assert/strict";
import {
  derivePayment,
  maxNetForBalance,
  DEFAULT_WHT_RATE,
  round2,
} from "./payment-wht.js";

test("DEFAULT_WHT_RATE is 1%", () => {
  assert.equal(DEFAULT_WHT_RATE, 0.01);
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
