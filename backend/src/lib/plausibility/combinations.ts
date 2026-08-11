// ─── Contextual net-weight combinations for receipt & delivery ─────────────
//
// Mirrors the production total-weight family (see total-weight.ts) but for the
// two single-metric operations:
//
//   • receipt  — metric = net_weight of a yarn_receipt_detail line.
//                dimensions: date, party, count (yarn count), brand (yarn brand)
//   • delivery — metric = net_weight of a daily_delivery row.
//                dimensions: date, party, type (yarn type), gsm_band
//
// For each operation we learn the distribution of per-key DAILY net-weight
// totals over a trailing window, then at listing-time flag any key whose day
// total falls outside the learned band. Each combination is stored as a normal
// plausibility_baseline row whose `field` encodes the operation + dimensions,
// e.g. "net_total@receipt:party+count". No schema change.
//
// Windowing matches production:
//   • Trailing 30-day window.
//   • Every combo aggregates per-day first (date is always in the GROUP BY),
//     so the learned quantity is a *daily* per-key total regardless of whether
//     Date is one of the naming dimensions.

import { sql, type SQL } from "drizzle-orm";
import { HardCap } from "./config.js";

/** Operations that carry the contextual net-weight family. */
export type ComboOperation = "receipt" | "delivery";

/** Dimensions available to each operation's combinations. */
export type ReceiptDimension = "date" | "party" | "count" | "brand";
export type DeliveryDimension = "date" | "party" | "type" | "gsm_band";
export type ComboDimension = ReceiptDimension | DeliveryDimension;

/** Canonical ordering per operation — keeps encoded field strings stable. */
const CANONICAL_ORDER: Record<ComboOperation, ComboDimension[]> = {
  receipt: ["date", "party", "count", "brand"],
  delivery: ["date", "party", "type", "gsm_band"],
};

/** Source table config per operation. */
interface OpSpec {
  /** FROM clause (with any master joins needed for labels added on demand). */
  base: string;
  /** The metric column (net weight). */
  metric: string;
  /** The header date column. */
  dateCol: string;
  /** reconciled / cancelled predicate for the still-editable listing rows. */
  editablePredicate: string;
  /** predicate for the trailing-window learning series. */
  windowPredicate: (windowDays: number) => SQL;
  /** Grouping SQL expression per dimension. */
  dimColumn: Record<string, string>;
  /** Readable label SQL per dimension (for the listing context string). */
  dimLabel: Record<string, string>;
  /** Master-table joins keyed by dimension (empty string if none). */
  dimJoin: Record<string, string>;
}

// Receipt: yarn_receipt_detail joined to its header. GSM has no meaning here.
const RECEIPT_SPEC: OpSpec = {
  base: "yarn_receipt_detail d JOIN yarn_receipt_header h ON h.id = d.header_id",
  metric: "d.net_weight",
  dateCol: "h.receipt_date",
  editablePredicate: "h.status <> 'cancelled' AND h.reconciled = false",
  windowPredicate: (w) =>
    sql`h.status <> 'cancelled' AND h.receipt_date >= (CURRENT_DATE - ${w}::int)`,
  dimColumn: {
    date: "h.receipt_date",
    party: "h.party_id",
    count: "d.yarn_count_id",
    brand: "d.yarn_brand_id",
  },
  dimLabel: {
    date: "h.receipt_date::text",
    party: "COALESCE(pm.name, 'Party ' || h.party_id::text)",
    count: "COALESCE(cm.count, 'Count ' || d.yarn_count_id::text)",
    brand: "COALESCE(bm.name, 'Brand ' || d.yarn_brand_id::text)",
  },
  dimJoin: {
    date: "",
    party: "LEFT JOIN party_master pm ON pm.id = h.party_id",
    count: "LEFT JOIN yarn_count_master cm ON cm.id = d.yarn_count_id",
    brand: "LEFT JOIN yarn_brand_master bm ON bm.id = d.yarn_brand_id",
  },
};

// Delivery: a single flat table. GSM is bucketed into coarse bands so the key
// space stays small and each band has enough history to learn from.
const GSM_BAND_SQL =
  "CASE WHEN d.gsm IS NULL THEN 'GSM n/a' " +
  "WHEN d.gsm < 120 THEN '<120' " +
  "WHEN d.gsm < 180 THEN '120–179' " +
  "WHEN d.gsm < 240 THEN '180–239' " +
  "WHEN d.gsm < 320 THEN '240–319' " +
  "ELSE '320+' END";

const DELIVERY_SPEC: OpSpec = {
  base: "daily_delivery d",
  metric: "d.net_weight",
  dateCol: "d.delivery_date",
  editablePredicate: "d.status <> 'cancelled' AND d.reconciled = false",
  windowPredicate: (w) =>
    sql`d.status <> 'cancelled' AND d.delivery_date >= (CURRENT_DATE - ${w}::int)`,
  dimColumn: {
    date: "d.delivery_date",
    party: "d.party_id",
    type: "d.yarn_type_id",
    gsm_band: GSM_BAND_SQL,
  },
  dimLabel: {
    date: "d.delivery_date::text",
    party: "COALESCE(pm.name, 'Party ' || d.party_id::text)",
    type: "COALESCE(tm.name, 'Type ' || d.yarn_type_id::text)",
    gsm_band: GSM_BAND_SQL,
  },
  dimJoin: {
    date: "",
    party: "LEFT JOIN party_master pm ON pm.id = d.party_id",
    type: "LEFT JOIN yarn_type_master tm ON tm.id = d.yarn_type_id",
    gsm_band: "",
  },
};

const SPEC: Record<ComboOperation, OpSpec> = {
  receipt: RECEIPT_SPEC,
  delivery: DELIVERY_SPEC,
};

/** Human labels for warning messages. */
const DIM_LABEL_TEXT: Record<ComboDimension, string> = {
  date: "Date",
  party: "Party",
  count: "Count",
  brand: "Brand",
  type: "Yarn type",
  gsm_band: "GSM band",
};

/**
 * Combinations per operation. Kept intentionally small and business-meaningful:
 * a party's daily intake, a party+product mix, a product-level daily total.
 * Order within each tuple is normalised by `canonical`.
 */
export const COMBINATIONS: Record<ComboOperation, ComboDimension[][]> = {
  receipt: [
    ["party"],
    ["count"],
    ["party", "count"],
    ["party", "brand"],
    ["count", "brand"],
    ["date", "party"],
    ["date", "party", "count"],
  ],
  delivery: [
    ["party"],
    ["type"],
    ["party", "type"],
    ["party", "gsm_band"],
    ["type", "gsm_band"],
    ["date", "party"],
    ["date", "party", "type"],
  ],
};

/** Sort a combination into its operation's canonical dimension order. */
export function canonical(operation: ComboOperation, dims: ComboDimension[]): ComboDimension[] {
  return CANONICAL_ORDER[operation].filter((d) => dims.includes(d));
}

/** Encoded plausibility_baseline `field` for a combination, e.g.
 *  ("receipt", ["count","party"]) → "net_total@receipt:party+count". */
export function comboField(operation: ComboOperation, dims: ComboDimension[]): string {
  return `net_total@${operation}:${canonical(operation, dims).join("+")}`;
}

/** Human label for a combination, e.g. "Party + Count". */
export function comboLabel(operation: ComboOperation, dims: ComboDimension[]): string {
  return canonical(operation, dims).map((d) => DIM_LABEL_TEXT[d]).join(" + ");
}

/** Every combination field string for an operation (for introspection). */
export function comboFields(operation: ComboOperation): string[] {
  return COMBINATIONS[operation].map((dims) => comboField(operation, dims));
}

/** True for any contextual net-total field. */
export function isNetTotalField(field: string): boolean {
  return /^net_total@(receipt|delivery):/.test(field);
}

/**
 * Hard sanity cap for a per-key daily net-weight total. A single line/row is
 * capped generously elsewhere; a per-key daily aggregate can be several rows,
 * so this ceiling is high — the learned band supplies the real context.
 */
export const NET_TOTAL_HARD_CAP: HardCap = { min: 0.5, max: 200_000 };

/** WINDOW_DAYS trailing days for baseline learning. */
export const WINDOW_DAYS = 30;

/**
 * Learning series for a combination: the distribution of per-key DAILY net
 * totals across the trailing window. Date is always in the GROUP BY so the
 * learned value is a daily total even for date-less combos.
 */
export function comboDailyTotalSeriesSQL(
  operation: ComboOperation,
  dims: ComboDimension[],
  windowDays = WINDOW_DAYS,
): SQL {
  const spec = SPEC[operation];
  const keyDims = canonical(operation, dims);

  const groupCols = new Set<string>([spec.dateCol]);
  for (const d of keyDims) groupCols.add(spec.dimColumn[d]);
  const groupList = sql.raw([...groupCols].join(", "));

  return sql`
    SELECT t.total::float8 AS v
    FROM (
      SELECT ${sql.raw([...groupCols].join(", "))}, SUM(${sql.raw(spec.metric)}) AS total
      FROM ${sql.raw(spec.base)}
      WHERE ${spec.windowPredicate(windowDays)}
      GROUP BY ${groupList}
    ) t
    WHERE t.total > 0`;
}

/**
 * Listing-time per-key daily totals for a SPECIFIC date and one combination.
 * Only still-editable (unreconciled, non-cancelled) rows are counted. Returns
 * one row per distinct key present that day, with positional label columns
 * (label_0, label_1, …) in canonical dimension order.
 */
export function comboTotalsForDateSQL(
  operation: ComboOperation,
  dims: ComboDimension[],
  date: string,
): SQL {
  const spec = SPEC[operation];
  const keyDims = canonical(operation, dims);

  const groupCols = new Set<string>([spec.dateCol]);
  for (const d of keyDims) groupCols.add(spec.dimColumn[d]);
  // Label expressions are non-aggregated → must also appear in GROUP BY.
  for (const d of keyDims) groupCols.add(spec.dimLabel[d]);
  const groupList = sql.raw([...groupCols].join(", "));

  const labelSelects = keyDims
    .map((d, i) => `${spec.dimLabel[d]} AS label_${i}`)
    .join(", ");
  const labelPrefix = labelSelects ? sql.raw(labelSelects + ", ") : sql.raw("");

  // Only the joins for dimensions actually in this combo.
  const joins = keyDims
    .map((d) => spec.dimJoin[d])
    .filter((j) => j.length > 0)
    .join(" ");
  const joinSql = joins ? sql.raw(joins) : sql.raw("");

  return sql`
    SELECT ${labelPrefix}SUM(${sql.raw(spec.metric)})::float8 AS total
    FROM ${sql.raw(spec.base)}
    ${joinSql}
    WHERE ${sql.raw(spec.editablePredicate)}
      AND ${sql.raw(spec.dateCol)} = ${date}::date
    GROUP BY ${groupList}`;
}
