// Unit tests for the total-weight combination key logic (pure helpers only).

import { test } from "node:test";
import assert from "node:assert/strict";

import {
  canonical,
  comboField,
  comboLabel,
  parseComboField,
  isTotalWeightField,
  TOTAL_WEIGHT_COMBINATIONS,
  TOTAL_WEIGHT_FIELD,
  type Dimension,
} from "./total-weight.js";

test("canonical: reorders dimensions into date,shift,machine,employee,party", () => {
  assert.deepEqual(canonical(["party", "machine", "date"]), ["date", "machine", "party"]);
  assert.deepEqual(canonical(["employee", "shift"]), ["shift", "employee"]);
});

test("comboField: stable regardless of input order", () => {
  assert.equal(comboField(["machine", "shift"]), "total_weight@shift+machine");
  assert.equal(comboField(["shift", "machine"]), "total_weight@shift+machine");
});

test("comboLabel: human readable, canonical order", () => {
  assert.equal(comboLabel(["party", "machine"]), "Machine + Party");
  assert.equal(comboLabel(["employee", "date", "shift"]), "Date + Shift + Employee");
});

test("parseComboField: round-trips comboField", () => {
  for (const dims of TOTAL_WEIGHT_COMBINATIONS) {
    const field = comboField(dims);
    const parsed = parseComboField(field);
    assert.deepEqual(parsed, canonical(dims), `round-trip failed for ${field}`);
  }
});

test("parseComboField: global field parses to empty dimension list", () => {
  assert.deepEqual(parseComboField(TOTAL_WEIGHT_FIELD), []);
});

test("parseComboField: rejects unknown field", () => {
  assert.equal(parseComboField("roll_weight"), null);
  assert.equal(parseComboField("total_weight@bogus+dim"), null);
});

test("isTotalWeightField: recognises global and combination fields", () => {
  assert.ok(isTotalWeightField(TOTAL_WEIGHT_FIELD));
  assert.ok(isTotalWeightField("total_weight@date+machine"));
  assert.equal(isTotalWeightField("roll_weight"), false);
});

test("the 26 requested combinations are all present and unique", () => {
  const fields = new Set(TOTAL_WEIGHT_COMBINATIONS.map(comboField));
  assert.equal(fields.size, 26, "expected 26 unique combinations");

  // Spot-check a few required entries from the issue's list.
  const required: Dimension[][] = [
    ["date"],
    ["machine", "party"],
    ["date", "shift", "machine", "employee", "party"],
    ["shift", "machine", "employee", "party"],
  ];
  for (const dims of required) {
    assert.ok(fields.has(comboField(dims)), `missing combination ${comboField(dims)}`);
  }
});

test("Party never appears without Machine or Employee (per the agreed list)", () => {
  // The requested list deliberately omits Party-only-with-Date/Shift combos.
  for (const dims of TOTAL_WEIGHT_COMBINATIONS) {
    const c = canonical(dims);
    if (c.includes("party")) {
      assert.ok(
        c.includes("machine") || c.includes("employee"),
        `combination ${comboField(dims)} has Party without Machine/Employee`,
      );
    }
  }
});
