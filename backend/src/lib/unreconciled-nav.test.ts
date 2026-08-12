// Unit tests for the pure SQL builder in unreconciled-nav.ts. No DB, no I/O.
// Run with: npm test  (Node's built-in test runner via tsx).
//
// These assert on the *shape* of the generated SQL rather than its execution:
// correct table/date column per operation, correct comparison direction, and
// the recon/unreconciled filter. Live query behaviour is covered by manual
// verification against the dev database (issue #120, Q9).

import { test } from "node:test";
import assert from "node:assert/strict";

import {
  buildUnreconciledNearestSql,
  UNRECONCILED_TABLE_MAP,
  type UnreconciledOperation,
} from "./unreconciled-nav.js";

const OPERATIONS: UnreconciledOperation[] = ["production", "receipt", "delivery"];

test("operation → table/date-column mapping is complete", () => {
  assert.deepEqual(
    Object.keys(UNRECONCILED_TABLE_MAP).sort(),
    ["delivery", "production", "receipt"],
  );
  assert.equal(UNRECONCILED_TABLE_MAP.production.dateColumn, "production_date");
  assert.equal(UNRECONCILED_TABLE_MAP.receipt.dateColumn, "receipt_date");
  assert.equal(UNRECONCILED_TABLE_MAP.delivery.dateColumn, "delivery_date");
});

test("selects the date formatted as YYYY-MM-DD via to_char", () => {
  for (const op of OPERATIONS) {
    const { sql } = buildUnreconciledNearestSql(op, "2026-08-12", "prev");
    assert.match(sql, /to_char\(.*'YYYY-MM-DD'\)/i, `${op} must format via to_char`);
  }
});

test("queries the correct table per operation", () => {
  assert.match(buildUnreconciledNearestSql("production", "2026-08-12", "prev").sql, /FROM daily_production_header/i);
  assert.match(buildUnreconciledNearestSql("receipt", "2026-08-12", "next").sql, /FROM yarn_receipt_header/i);
  assert.match(buildUnreconciledNearestSql("delivery", "2026-08-12", "prev").sql, /FROM daily_delivery\b/i);
});

test("prev uses strict less-than, DESC ordering, and LIMIT 1", () => {
  for (const op of OPERATIONS) {
    const { sql, params } = buildUnreconciledNearestSql(op, "2026-08-12", "prev");
    assert.match(sql, /< \$1::date/, `${op} prev must use strict <`);
    assert.match(sql, /ORDER BY .* DESC/i, `${op} prev must order DESC`);
    assert.match(sql, /LIMIT 1/i, `${op} prev must LIMIT 1`);
    assert.deepEqual(params, ["2026-08-12"]);
  }
});

test("next uses strict greater-than, ASC ordering, and LIMIT 1", () => {
  for (const op of OPERATIONS) {
    const { sql, params } = buildUnreconciledNearestSql(op, "2026-08-12", "next");
    assert.match(sql, /> \$1::date/, `${op} next must use strict >`);
    assert.match(sql, /ORDER BY .* ASC/i, `${op} next must order ASC`);
    assert.match(sql, /LIMIT 1/i, `${op} next must LIMIT 1`);
    assert.deepEqual(params, ["2026-08-12"]);
  }
});

test("applies the unreconciled filter (reconciled=false, status<>'cancelled')", () => {
  for (const op of OPERATIONS) {
    const { sql } = buildUnreconciledNearestSql(op, "2026-08-12", "next");
    assert.match(sql, /reconciled\s*=\s*false/i, `${op} must filter reconciled=false`);
    assert.match(sql, /status\s*<>\s*'cancelled'/i, `${op} must exclude cancelled`);
  }
});
