// Unit tests for the transaction reconcile-source derivation (issue #130).
// Deleting a line must not reconcile the deleted record: the reconcile set is
// derived from the source ids on the detail lines the user actually kept.
// Run with: npm test  (Node's built-in test runner via tsx).

import { test } from "node:test";
import assert from "node:assert/strict";

import {
  collectReconcileSourceIds,
  deriveReconcileSets,
} from "./reconcile-derive.js";

// ─── collectReconcileSourceIds ────────────────────────────────────────────

test("collect: returns the source ids of the kept lines", () => {
  assert.deepEqual(
    collectReconcileSourceIds([
      { reconcileSourceId: 11 },
      { reconcileSourceId: 22 },
    ]),
    [11, 22],
  );
});

test("collect: a deleted line's id is absent -> excluded from the reconcile set", () => {
  // Simulates deleting one of two loaded deliveries: only line 22 remains.
  assert.deepEqual(
    collectReconcileSourceIds([{ reconcileSourceId: 22 }]),
    [22],
  );
});

test("collect: ignores invalid/empty source ids", () => {
  assert.deepEqual(
    collectReconcileSourceIds([
      { reconcileSourceId: 5 },
      {}, // no id
      { reconcileSourceId: "7" }, // string, not int
      { reconcileSourceId: -3 }, // not positive
      { reconcileSourceId: 2.5 }, // not integer
    ]),
    [5],
  );
});

test("collect: empty details -> empty reconcile set", () => {
  assert.deepEqual(collectReconcileSourceIds([]), []);
});

test("collect: dedupes a multi-line receipt header (claimed once, not once per line)", () => {
  // A Yarn Receipt header (id 77) with three lines appears on three detail
  // rows; it must be claimed once, so the backend's claimed-count guard passes.
  assert.deepEqual(
    collectReconcileSourceIds([
      { reconcileSourceId: 77 },
      { reconcileSourceId: 77 },
      { reconcileSourceId: 77 },
    ]),
    [77],
  );
});

test("collect: dedup keeps order and drops removed lines", () => {
  // Two receipts, then one line of receipt B removed -> only kept headers.
  assert.deepEqual(
    collectReconcileSourceIds([
      { reconcileSourceId: 10 },
      { reconcileSourceId: 20 },
      { reconcileSourceId: 20 }, // second line of receipt 20
    ]),
    [10, 20],
  );
});

// ─── deriveReconcileSets ──────────────────────────────────────────────────

test("derive: routes ids to the production bucket", () => {
  const sets = deriveReconcileSets([10, 20], "Fabric_Production");
  assert.deepEqual(sets.reconcileProductionIds, [10, 20]);
  assert.deepEqual(sets.reconcileReceiptIds, []);
  assert.deepEqual(sets.reconcileDeliveryIds, []);
});

test("derive: routes ids to the receipt bucket", () => {
  const sets = deriveReconcileSets([30], "Yarn_Receipt");
  assert.deepEqual(sets.reconcileReceiptIds, [30]);
  assert.deepEqual(sets.reconcileProductionIds, []);
  assert.deepEqual(sets.reconcileDeliveryIds, []);
});

test("derive: routes ids to the delivery bucket (Fabric_Dispatch)", () => {
  const sets = deriveReconcileSets([40, 50], "Fabric_Dispatch");
  assert.deepEqual(sets.reconcileDeliveryIds, [40, 50]);
  assert.deepEqual(sets.reconcileProductionIds, []);
  assert.deepEqual(sets.reconcileReceiptIds, []);
});

test("derive: unknown/empty code yields no reconcile buckets", () => {
  assert.deepEqual(deriveReconcileSets([1], "Something_Else"), {
    reconcileProductionIds: [],
    reconcileReceiptIds: [],
    reconcileDeliveryIds: [],
  });
});

test("derive: empty source ids yields empty buckets", () => {
  assert.deepEqual(deriveReconcileSets([], "Fabric_Dispatch"), {
    reconcileProductionIds: [],
    reconcileReceiptIds: [],
    reconcileDeliveryIds: [],
  });
});
