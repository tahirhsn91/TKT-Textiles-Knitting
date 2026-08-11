// Unit tests for the pure helpers of the contextual net-total combinations
// module (receipt & delivery). No DB — only the encoding/label/ordering logic.

import { test } from "node:test";
import assert from "node:assert/strict";

import {
  canonical,
  comboField,
  comboLabel,
  comboFields,
  isNetTotalField,
  COMBINATIONS,
} from "./combinations.js";

// ─── canonical ordering ─────────────────────────────────────────────────────

test("canonical: receipt orders dims date→party→count→brand regardless of input", () => {
  assert.deepEqual(canonical("receipt", ["brand", "count", "party"]), ["party", "count", "brand"]);
  assert.deepEqual(canonical("receipt", ["count", "date"]), ["date", "count"]);
});

test("canonical: delivery orders dims date→party→type→gsm_band", () => {
  assert.deepEqual(canonical("delivery", ["gsm_band", "type", "party"]), ["party", "type", "gsm_band"]);
});

// ─── field encoding ─────────────────────────────────────────────────────────

test("comboField: encodes operation + canonical dims", () => {
  assert.equal(comboField("receipt", ["count", "party"]), "net_total@receipt:party+count");
  assert.equal(comboField("delivery", ["gsm_band", "party"]), "net_total@delivery:party+gsm_band");
});

test("comboField: stable regardless of input order", () => {
  assert.equal(
    comboField("receipt", ["brand", "party"]),
    comboField("receipt", ["party", "brand"]),
  );
});

// ─── labels ─────────────────────────────────────────────────────────────────

test("comboLabel: human dimension names in canonical order", () => {
  assert.equal(comboLabel("receipt", ["count", "party"]), "Party + Count");
  assert.equal(comboLabel("delivery", ["gsm_band", "type"]), "Yarn type + GSM band");
});

// ─── field recognition ──────────────────────────────────────────────────────

test("isNetTotalField: recognises encoded combo fields, rejects others", () => {
  assert.ok(isNetTotalField("net_total@receipt:party"));
  assert.ok(isNetTotalField("net_total@delivery:party+type"));
  assert.equal(isNetTotalField("total_weight@shift+machine"), false);
  assert.equal(isNetTotalField("net_weight"), false);
});

// ─── combo catalogue integrity ──────────────────────────────────────────────

test("comboFields: every configured combination yields a unique field", () => {
  for (const op of ["receipt", "delivery"] as const) {
    const fields = comboFields(op);
    const unique = new Set(fields);
    assert.equal(unique.size, fields.length, `${op} has duplicate combo field encodings`);
    assert.equal(fields.length, COMBINATIONS[op].length);
    // Every field is recognised by the guard used to route feedback/introspection.
    assert.ok(fields.every(isNetTotalField), `${op} produced an unrecognised field`);
  }
});
