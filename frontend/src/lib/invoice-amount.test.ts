import { test } from "node:test";
import assert from "node:assert/strict";
import { amountInWords } from "./invoice-amount.js";

test("amountInWords: whole rupees convert to words", () => {
  assert.equal(amountInWords(1234), "One Thousand Two Hundred Thirty-Four Only");
});

test("amountInWords: rounds amount to zero decimal places before conversion", () => {
  // 1234.5 rounds to 1235
  assert.equal(amountInWords(1234.5), "One Thousand Two Hundred Thirty-Five Only");
  // 1234.4 rounds to 1234
  assert.equal(amountInWords(1234.4), "One Thousand Two Hundred Thirty-Four Only");
});

test("amountInWords: string input with decimals is rounded (exactly .5 rounds up)", () => {
  assert.equal(amountInWords("1234.6"), "One Thousand Two Hundred Thirty-Five Only");
  assert.equal(amountInWords("1234.49"), "One Thousand Two Hundred Thirty-Four Only");
});

test("amountInWords: fractional paisa is dropped after rounding, no paisa phrase", () => {
  // 100.60 → 101, and output must not contain "Paisa"
  const w = amountInWords(100.6);
  assert.equal(w, "One Hundred One Only");
  assert.ok(!w.includes("Paisa"));
});

test("amountInWords: large amount with lakh and crore grouping", () => {
  // 1,23,45,678 → One Crore Twenty Three Lakh Forty Five Thousand Six Hundred Seventy Eight
  assert.equal(amountInWords(12345678), "One Crore Twenty-Three Lakh Forty-Five Thousand Six Hundred Seventy-Eight Only");
});

test("amountInWords: rounds large fractional amount up", () => {
  assert.equal(amountInWords(9999999.6), "One Crore Only");
});

test("amountInWords: zero and negative return Zero Only", () => {
  assert.equal(amountInWords(0), "Zero Only");
  assert.equal(amountInWords(-5), "Zero Only");
  assert.equal(amountInWords(""), "Zero Only");
});
