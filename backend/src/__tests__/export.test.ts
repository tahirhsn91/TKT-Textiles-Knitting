import { test } from "node:test";
import assert from "node:assert/strict";
import { csvField, toCsv } from "../lib/export.js";

test("csvField: plain values are unchanged", () => {
  assert.equal(csvField("abc"), "abc");
  assert.equal(csvField(123), "123");
  assert.equal(csvField(null), "");
  assert.equal(csvField(undefined), "");
});

test("csvField: asText prefixes a TAB so Excel keeps the value as text", () => {
  assert.equal(csvField("00123", { asText: true }), "\t00123");
  assert.equal(csvField(123456789012345, { asText: true }), "\t123456789012345");
});

test("csvField: empty values are not prefixed with a TAB", () => {
  assert.equal(csvField("", { asText: true }), "");
  assert.equal(csvField(null, { asText: true }), "");
});

test("csvField: asText still quotes values containing CSV specials", () => {
  assert.equal(csvField("A,001", { asText: true }), "\"\tA,001\"");
  assert.equal(csvField('say "hi"', { asText: true }), "\"\tsay \"\"hi\"\"\"");
});

test("toCsv: only textColumns are forced to text", () => {
  const csv = toCsv(
    ["Date", "Doc No", "Reference", "Qty"],
    [["2026-10-21", "00123", "12345", 7]],
    "\n",
    [1, 2],
  );
  const [header, row] = csv.trimEnd().split("\n");
  assert.equal(header, "Date,Doc No,Reference,Qty");
  assert.equal(row, "2026-10-21,\t00123,\t12345,7");
});

test("toCsv: no textColumns behaves exactly as before", () => {
  const csv = toCsv(["A", "B"], [["001", 2]], "\n");
  assert.equal(csv, "A,B\n001,2\n");
});

test("toCsv: text columns preserve leading zeros and long numeric ids", () => {
  const csv = toCsv(
    ["Doc No", "Reference"],
    [["000123", "99999999999999999999"]],
    "\n",
    [0, 1],
  );
  assert.equal(csv, "Doc No,Reference\n\t000123,\t99999999999999999999\n");
});
