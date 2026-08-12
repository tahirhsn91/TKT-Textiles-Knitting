/**
 * Reconciliation-source derivation for transaction creation (issue #130).
 *
 * When a daily-operations transaction is created, the source records it claims
 * (daily production headers, yarn receipt headers, or daily deliveries) are
 * derived from the detail lines the user actually kept. Each detail line
 * carries a `reconcileSourceId` (set by the frontend auto-fill). Deleting a
 * line removes its source id from the visible details, so it must also be
 * excluded from the reconcile set — fixing the bug where deleting a line still
 * reconciled the deleted record.
 *
 * The reconcile set is routed to the right bucket by the transaction type code:
 *   - Fabric_Production -> reconcileProductionIds
 *   - Yarn_Receipt       -> reconcileReceiptIds
 *   - Fabric_Dispatch    -> reconcileDeliveryIds  ("Fabric Delivery")
 * Only one bucket applies per transaction.
 */

export interface ReconcileSource {
  /** Source record id (daily production header / yarn receipt header / daily delivery). */
  reconcileSourceId?: unknown;
}

export type ReconcileSets = {
  reconcileProductionIds: number[];
  reconcileReceiptIds: number[];
  reconcileDeliveryIds: number[];
};

const toPositiveInt = (v: unknown): number | null =>
  typeof v === "number" && Number.isInteger(v) && v > 0 ? v : null;

/**
 * Collect the positive, integer source ids from the submitted detail lines
 * (the records the user actually kept), deduplicated and order-preserving.
 *
 * Deduplication matters for Yarn Receipts: a receipt header can span several
 * transaction lines (one per receipt line), each carrying the same header id.
 * The reconcile unit is the header, so it must be claimed once — not once per
 * line, which would otherwise fail the backend's claimed-count guard.
 */
export function collectReconcileSourceIds(details: ReconcileSource[]): number[] {
  const seen = new Set<number>();
  const out: number[] = [];
  for (const d of details) {
    const id = toPositiveInt(d?.reconcileSourceId);
    if (id == null || seen.has(id)) continue;
    seen.add(id);
    out.push(id);
  }
  return out;
}

/**
 * Route a set of source ids to the reconcile bucket for the given transaction
 * type code. Only one bucket is populated (the one matching the code).
 */
export function deriveReconcileSets(
  sourceIds: number[],
  transactionTypeCode: string | undefined,
): ReconcileSets {
  const empty: ReconcileSets = { reconcileProductionIds: [], reconcileReceiptIds: [], reconcileDeliveryIds: [] };
  if (!transactionTypeCode || sourceIds.length === 0) return empty;
  if (transactionTypeCode === "Fabric_Production") return { ...empty, reconcileProductionIds: sourceIds };
  if (transactionTypeCode === "Yarn_Receipt") return { ...empty, reconcileReceiptIds: sourceIds };
  if (transactionTypeCode === "Fabric_Dispatch") return { ...empty, reconcileDeliveryIds: sourceIds };
  return empty;
}
