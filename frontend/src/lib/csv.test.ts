import { test } from "node:test";
import assert from "node:assert/strict";
import { csvField, toCSV } from "./csv.js";

test("csvField: plain values unchanged", () => {
  assert.equal(csvField("abc"), "abc");
  assert.equal(csvField(123), "123");
  assert.equal(csvField(null), "");
});

test("csvField: values containing commas are quoted", () => {
  assert.equal(csvField("3751,3752"), '"3751,3752"');
});

test("csvField: asText prefixes a TAB (inside the quotes when quoted)", () => {
  assert.equal(csvField("3751,3752", true), '"\t3751,3752"');
  assert.equal(csvField("00123", true), "\t00123");
});

test("csvField: empty values are never prefixed", () => {
  assert.equal(csvField("", true), "");
  assert.equal(csvField(null, true), "");
});

test("toCSV: forces only the named columns to text, by header name", () => {
  const csv = toCSV(
    ["Date", "Doc Number", "Reference", "Qty"],
    [["2026-10-23", "3751,3752", "3755,3756", 7]],
    ["Doc Number", "Reference"],
  );
  assert.equal(
    csv,
    'Date,Doc Number,Reference,Qty\r\n2026-10-23,"\t3751,3752","\t3755,3756",7',
  );
});

test("toCSV: column order does not matter (resolved by name)", () => {
  const csv = toCSV(
    ["Reference", "Date", "Doc Number"],
    [["3755,3756", "2026-10-23", "3751,3752"]],
    ["Doc Number", "Reference"],
  );
  assert.equal(csv, 'Reference,Date,Doc Number\r\n"\t3755,3756",2026-10-23,"\t3751,3752"');
});

test("toCSV: unknown text columns are ignored", () => {
  const csv = toCSV(["A", "B"], [["001", "002"]], ["Nope"]);
  assert.equal(csv, "A,B\r\n001,002");
});

test("toCSV: headers are never text-prefixed", () => {
  const csv = toCSV(["Doc Number"], [["123,456"]], ["Doc Number"]);
  assert.equal(csv, 'Doc Number\r\n"\t123,456"');
});
