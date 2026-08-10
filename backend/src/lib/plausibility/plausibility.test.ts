// Unit tests for the pure plausibility layer (stats + check). No DB, no I/O.
// Run with: npm test  (uses Node's built-in test runner via tsx).

import { test } from "node:test";
import assert from "node:assert/strict";

import { median, iqr, mad, boundsFromSummary, robustSummary } from "./stats.js";
import { checkField, checkEntry, deriveFieldValues } from "./check.js";
import type { BaselineEntry } from "./check.js";

// ─── Robust statistics ─────────────────────────────────────────────────────

test("median: odd and even length", () => {
  assert.equal(median([3, 1, 2]), 2);
  assert.equal(median([1, 2, 3, 4]), 2.5);
});

test("median: empty is NaN", () => {
  assert.ok(Number.isNaN(median([])));
});

test("iqr: quartile spread", () => {
  // 1..9 → Q1=3, Q3=7 (type-7 interpolation) → IQR=4
  assert.equal(iqr([1, 2, 3, 4, 5, 6, 7, 8, 9]), 4);
});

test("mad: scaled median absolute deviation is non-zero for spread data", () => {
  assert.ok(mad([1, 2, 3, 4, 5]) > 0);
});

test("median is unaffected by a gross outlier", () => {
  // The whole point: a 2181 kg 'roll' among ~30 kg rolls must not move center.
  // Odd-length clean set has median 30; adding one outlier makes it even-length
  // (median = mean of the two middle CLEAN values, 30 & 31 = 30.5) — crucially
  // still ~30, not dragged toward 2181 the way a mean would be.
  const clean = [28, 29, 30, 31, 32];
  assert.equal(median(clean), 30);
  assert.equal(median([...clean, 2181.85]), 30.5);
  // A mean, by contrast, is destroyed by the outlier.
  const mean = (arr: number[]) => arr.reduce((a, b) => a + b, 0) / arr.length;
  assert.ok(mean([...clean, 2181.85]) > 300, "mean is poisoned by the outlier");
});

// ─── Bounds ────────────────────────────────────────────────────────────────

test("boundsFromSummary: median ± k·IQR, clamped at zero", () => {
  const s = robustSummary([10, 20, 30, 40, 50]); // median 30
  const b = boundsFromSummary(s, 3);
  assert.ok(b.lower >= 0);
  assert.ok(b.upper > b.lower);
});

test("boundsFromSummary: degenerate (all identical) collapses to median", () => {
  const s = robustSummary([5, 5, 5, 5, 5]);
  const b = boundsFromSummary(s, 3);
  assert.equal(b.lower, 5);
  assert.equal(b.upper, 5);
});

test("boundsFromSummary: uses MAD when IQR is zero but data still has spread", () => {
  // A distribution where fewer than half sit exactly at the median keeps a
  // non-zero MAD even if the IQR happens to be small, so the band stays real.
  const values = [5, 7, 10, 10, 10, 13, 90, 95];
  const s = robustSummary(values);
  assert.ok(s.mad > 0, "precondition: MAD is non-zero");
  const b = boundsFromSummary(s, 3);
  assert.ok(b.upper > b.lower, "non-degenerate band expected");
});

test("boundsFromSummary: degenerates to median when bulk of data is identical", () => {
  // When >=50% of values equal the median, both IQR and MAD collapse to 0 —
  // there is genuinely no learned spread, so bounds degenerate and the caller
  // (checkField) falls back to the hard sanity caps. This is intended.
  const values = [2, 4, 10, 10, 10, 10, 10, 10, 16, 18];
  const s = robustSummary(values);
  assert.equal(s.iqr, 0);
  assert.equal(s.mad, 0);
  const b = boundsFromSummary(s, 3);
  assert.equal(b.lower, b.upper, "degenerate band collapses to the median");
});

// ─── checkField ────────────────────────────────────────────────────────────

const learned: BaselineEntry = {
  median: 30, iqr: 4, mad: 3, lowerBound: 18, upperBound: 42, sampleCount: 500,
};

test("checkField: value inside learned band → no warning", () => {
  assert.equal(checkField("roll_weight", 30, learned), null);
});

test("checkField: value outside learned band → learned warning", () => {
  const w = checkField("roll_weight", 45, learned);
  assert.ok(w);
  assert.equal(w?.source, "learned");
});

test("checkField: physically impossible value → hard_cap warning even inside history", () => {
  const w = checkField("roll_weight", 2181.85, learned);
  assert.ok(w);
  assert.equal(w?.source, "hard_cap");
});

test("checkField: thin baseline (below MIN_SAMPLE_COUNT) ignores learned band", () => {
  const thin: BaselineEntry = { ...learned, sampleCount: 5 };
  // 45 is outside the learned band but within the hard cap → no warning,
  // because we don't trust a 5-sample baseline.
  assert.equal(checkField("roll_weight", 45, thin), null);
});

test("checkField: thin baseline still enforces hard caps", () => {
  const thin: BaselineEntry = { ...learned, sampleCount: 5 };
  const w = checkField("roll_weight", 999, thin);
  assert.ok(w);
  assert.equal(w?.source, "hard_cap");
});

test("checkField: no baseline at all → hard caps only", () => {
  assert.equal(checkField("roll_weight", 30, undefined), null);
  assert.ok(checkField("roll_weight", 999, undefined));
});

test("checkField: non-finite value → no warning (never throws)", () => {
  assert.equal(checkField("roll_weight", NaN, learned), null);
  assert.equal(checkField("roll_weight", Infinity, undefined), null);
});

// ─── deriveFieldValues (ratios) ─────────────────────────────────────────────

test("deriveFieldValues: receipt derives wt_per_bag", () => {
  const vals = deriveFieldValues("receipt", { netWeight: 453.6, quantity: 10 });
  const perBag = vals.find((v) => v.field === "wt_per_bag");
  assert.ok(perBag);
  assert.equal(perBag?.value, 45.36);
});

test("deriveFieldValues: delivery derives wt_per_roll and passes gsm", () => {
  const vals = deriveFieldValues("delivery", { netWeight: 300, quantity: 10, gsm: 250 });
  assert.ok(vals.find((v) => v.field === "wt_per_roll" && v.value === 30));
  assert.ok(vals.find((v) => v.field === "gsm" && v.value === 250));
});

test("deriveFieldValues: quantity 0 does not produce a divide-by-zero ratio", () => {
  const vals = deriveFieldValues("receipt", { netWeight: 100, quantity: 0 });
  assert.equal(vals.find((v) => v.field === "wt_per_bag"), undefined);
});

test("deriveFieldValues: production expands each roll weight", () => {
  const vals = deriveFieldValues("production", { rollWeights: [28, 30, 32] });
  assert.equal(vals.length, 3);
  assert.ok(vals.every((v) => v.field === "roll_weight"));
});

// ─── checkEntry (end to end, pure) ──────────────────────────────────────────

test("checkEntry: flags the abnormal roll among normal ones", () => {
  const baselines = { roll_weight: learned };
  const warnings = checkEntry("production", { rollWeights: [30, 2181.85, 29] }, baselines);
  assert.equal(warnings.length, 1);
  assert.equal(warnings[0].value, 2181.85);
});

test("checkEntry: clean entry yields no warnings", () => {
  const baselines = { roll_weight: learned };
  const warnings = checkEntry("production", { rollWeights: [28, 30, 31] }, baselines);
  assert.equal(warnings.length, 0);
});

test("checkEntry: receipt with a lot total mis-entered as 1 bag is flagged", () => {
  const wtPerBag: BaselineEntry = {
    median: 45, iqr: 6, mad: 5, lowerBound: 20, upperBound: 70, sampleCount: 100,
  };
  const warnings = checkEntry("receipt", { netWeight: 7436, quantity: 1 }, { wt_per_bag: wtPerBag });
  assert.ok(warnings.some((w) => w.field === "wt_per_bag"));
});
