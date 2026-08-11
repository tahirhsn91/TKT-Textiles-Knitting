// ─── Plausibility engine (DB-facing) ───────────────────────────────────────
// Ties the pure stats + check to the database: loads learned baselines,
// recomputes them from clean history, records operator feedback, and validates
// the unreconciled rows shown on a listing page.
//
// All operations here are best-effort and non-fatal for the caller's happy
// path: the incremental retrain after an insert must never fail the insert, so
// callers wrap the retrain in try/catch and log. The functions themselves
// throw only on genuine DB errors.

import { sql } from "drizzle-orm";
import { db } from "../../db/index.js";
import {
  plausibilityBaselineTable,
  plausibilityFeedbackTable,
} from "../../db/schema/plausibility.js";
import { logger } from "../logger.js";
import { robustSummary, boundsFromSummary } from "./stats.js";
import {
  K,
  OPERATION_FIELDS,
  type Operation,
  type PlausibilityField,
} from "./config.js";
import {
  checkEntry,
  checkValue,
  type BaselineEntry,
  type BaselineMap,
  type PlausibilityWarning,
} from "./check.js";
import {
  TOTAL_WEIGHT_COMBINATIONS,
  TOTAL_WEIGHT_FIELD,
  TOTAL_WEIGHT_HARD_CAP,
  perEntryTotalSeriesSQL,
  comboDailyTotalSeriesSQL,
  comboTotalsForDateSQL,
  comboField,
  comboLabel,
  canonical,
  type Dimension,
} from "./total-weight.js";
import {
  COMBINATIONS as NET_TOTAL_COMBINATIONS,
  NET_TOTAL_HARD_CAP,
  comboDailyTotalSeriesSQL as netComboSeriesSQL,
  comboTotalsForDateSQL as netComboTotalsForDateSQL,
  comboField as netComboField,
  comboLabel as netComboLabel,
  canonical as netCanonical,
  type ComboOperation,
} from "./combinations.js";

export type { PlausibilityWarning } from "./check.js";

// ─── History extraction ────────────────────────────────────────────────────
// Raw numeric series per (operation, field), read from the clean operational
// data — cancelled rows excluded, ratios computed in SQL so the JS side only
// deals with plain number arrays.

const HISTORY_SQL: Record<Operation, Partial<Record<PlausibilityField, ReturnType<typeof sql>>>> = {
  production: {
    roll_weight: sql`
      SELECT d.roll_weight::float8 AS v
      FROM daily_production_detail d
      JOIN daily_production_header h ON h.id = d.header_id
      WHERE h.status <> 'cancelled' AND d.roll_weight > 0`,
  },
  receipt: {
    net_weight: sql`
      SELECT d.net_weight::float8 AS v
      FROM yarn_receipt_detail d
      JOIN yarn_receipt_header h ON h.id = d.header_id
      WHERE h.status <> 'cancelled' AND d.net_weight > 0`,
    quantity: sql`
      SELECT d.quantity::float8 AS v
      FROM yarn_receipt_detail d
      JOIN yarn_receipt_header h ON h.id = d.header_id
      WHERE h.status <> 'cancelled' AND d.quantity > 0`,
    wt_per_bag: sql`
      SELECT (d.net_weight / d.quantity)::float8 AS v
      FROM yarn_receipt_detail d
      JOIN yarn_receipt_header h ON h.id = d.header_id
      WHERE h.status <> 'cancelled' AND d.quantity > 0 AND d.net_weight > 0`,
  },
  delivery: {
    net_weight: sql`
      SELECT net_weight::float8 AS v
      FROM daily_delivery
      WHERE status <> 'cancelled' AND net_weight > 0`,
    quantity: sql`
      SELECT quantity::float8 AS v
      FROM daily_delivery
      WHERE status <> 'cancelled' AND quantity > 0`,
    gsm: sql`
      SELECT gsm::float8 AS v
      FROM daily_delivery
      WHERE status <> 'cancelled' AND gsm IS NOT NULL AND gsm > 0`,
    wt_per_roll: sql`
      SELECT (net_weight / quantity)::float8 AS v
      FROM daily_delivery
      WHERE status <> 'cancelled' AND quantity > 0 AND net_weight > 0`,
  },
};

async function fetchSeries(operation: Operation, field: PlausibilityField): Promise<number[]> {
  const query = HISTORY_SQL[operation]?.[field];
  if (!query) return [];
  const { rows } = await db.execute<{ v: number }>(query);
  return rows.map((r) => Number(r.v)).filter((v) => Number.isFinite(v));
}

// ─── Baseline recompute ────────────────────────────────────────────────────

/** Upsert one learned baseline row from a raw numeric series. */
async function upsertBaseline(operation: Operation, field: string, values: number[]): Promise<void> {
  if (values.length === 0) return;
  const summary = robustSummary(values);
  const bounds = boundsFromSummary(summary, K);
  const set = {
    median: String(summary.median),
    iqr: String(summary.iqr),
    mad: String(summary.mad),
    lowerBound: String(bounds.lower),
    upperBound: String(bounds.upper),
    sampleCount: summary.sampleCount,
    computedAt: new Date(),
  };
  await db
    .insert(plausibilityBaselineTable)
    .values({ operation, field, ...set })
    .onConflictDoUpdate({
      target: [plausibilityBaselineTable.operation, plausibilityBaselineTable.field],
      set,
    });
}

/** Read a raw float series from an arbitrary SQL query returning column `v`. */
async function execSeries(query: ReturnType<typeof sql>): Promise<number[]> {
  const { rows } = await db.execute<{ v: number }>(query);
  return rows.map((r) => Number(r.v)).filter((v) => Number.isFinite(v));
}

/** Recompute and upsert the baseline for every field of one operation. */
export async function retrainOperation(operation: Operation): Promise<void> {
  for (const field of OPERATION_FIELDS[operation]) {
    const values = await fetchSeries(operation, field);
    await upsertBaseline(operation, field, values);
  }

  // Production also carries the total-weight family: A (per-entry total) plus
  // the 26 contextual combinations, all learned over the trailing window.
  if (operation === "production") {
    await upsertBaseline("production", TOTAL_WEIGHT_FIELD, await execSeries(perEntryTotalSeriesSQL()));
    for (const dims of TOTAL_WEIGHT_COMBINATIONS) {
      await upsertBaseline("production", comboField(dims), await execSeries(comboDailyTotalSeriesSQL(dims)));
    }
  }

  // Receipt and delivery carry the contextual net-total family: per-key daily
  // net-weight totals across a handful of business-meaningful dimension combos.
  if (operation === "receipt" || operation === "delivery") {
    const op = operation as ComboOperation;
    for (const dims of NET_TOTAL_COMBINATIONS[op]) {
      await upsertBaseline(op, netComboField(op, dims), await execSeries(netComboSeriesSQL(op, dims)));
    }
  }
}

/** Full rebuild across all operations (manual /retrain endpoint). */
export async function retrainAll(): Promise<{ operation: Operation; fields: number }[]> {
  const result: { operation: Operation; fields: number }[] = [];
  for (const operation of Object.keys(OPERATION_FIELDS) as Operation[]) {
    await retrainOperation(operation);
    result.push({ operation, fields: OPERATION_FIELDS[operation].length });
  }
  return result;
}

/**
 * Incremental retrain fired after a successful insert. Non-fatal by contract:
 * swallows and logs any error so it can never turn a good insert into a 500.
 */
export async function retrainAfterInsert(operation: Operation): Promise<void> {
  try {
    await retrainOperation(operation);
  } catch (err) {
    logger.error({ err, operation }, "plausibility: incremental retrain failed (non-fatal)");
  }
}

// ─── Baseline load ─────────────────────────────────────────────────────────

export async function loadBaselines(operation: Operation): Promise<BaselineMap> {
  const rows = await db
    .select()
    .from(plausibilityBaselineTable)
    .where(sql`${plausibilityBaselineTable.operation} = ${operation}`);

  const map: BaselineMap = {};
  for (const r of rows) {
    const entry: BaselineEntry = {
      median: Number(r.median),
      iqr: Number(r.iqr),
      mad: Number(r.mad),
      lowerBound: Number(r.lowerBound),
      upperBound: Number(r.upperBound),
      sampleCount: r.sampleCount,
    };
    map[r.field as PlausibilityField] = entry;
  }
  return map;
}

/** All baselines across every operation — for introspection / debugging. */
export async function getAllBaselines() {
  return db.select().from(plausibilityBaselineTable);
}

// ─── Single-entry validation (insert-time) ─────────────────────────────────

export async function validateEntry(
  operation: Operation,
  raw: { rollWeights?: number[]; netWeight?: number; quantity?: number; gsm?: number | null },
): Promise<PlausibilityWarning[]> {
  const baselines = await loadBaselines(operation);
  const warnings = checkEntry(operation, raw, baselines);

  // Production also checks the per-entry TOTAL weight (combination A) at
  // insert-time. The contextual combinations are listing-time only.
  if (operation === "production" && raw.rollWeights && raw.rollWeights.length > 0) {
    const total = raw.rollWeights.reduce((s, w) => s + (Number.isFinite(w) ? w : 0), 0);
    const w = checkValue(
      TOTAL_WEIGHT_FIELD,
      "Total weight",
      total,
      TOTAL_WEIGHT_HARD_CAP,
      baselines[TOTAL_WEIGHT_FIELD as PlausibilityField],
    );
    if (w) warnings.push(w);
  }

  return warnings;
}

// ─── Feedback ──────────────────────────────────────────────────────────────

export type FeedbackOutcome = "confirmed_anyway" | "corrected";

export async function recordFeedback(entries: {
  operation: Operation;
  field: PlausibilityField;
  enteredValue: number;
  expectedLow?: number | null;
  expectedHigh?: number | null;
  outcome: FeedbackOutcome;
  createdBy?: string | null;
}[]): Promise<void> {
  if (entries.length === 0) return;
  await db.insert(plausibilityFeedbackTable).values(
    entries.map((e) => ({
      operation: e.operation,
      field: e.field,
      enteredValue: String(e.enteredValue),
      expectedLow: e.expectedLow != null ? String(e.expectedLow) : null,
      expectedHigh: e.expectedHigh != null ? String(e.expectedHigh) : null,
      outcome: e.outcome,
      createdBy: e.createdBy ?? null,
    })),
  );
}

// ─── Listing-page validation (unreconciled rows only) ──────────────────────
// Runs the check against the still-editable rows of an operation and reports
// how many are abnormal. Reconciled and cancelled rows are excluded: they are
// locked audit records, so warning about them is noise.

export interface ListRowFinding {
  id: number;
  warnings: PlausibilityWarning[];
}

/** A flagged contextual combination total (listing-time, production only). */
export interface CombinationFinding {
  /** Encoded key, e.g. "total_weight@shift+machine". */
  field: string;
  /** Human dimension label, e.g. "Shift + Machine". */
  combination: string;
  /** Human description of the specific key instance, e.g. "Machine 25, Morning". */
  context: string;
  value: number;
  expectedLow: number;
  expectedHigh: number;
  source: "learned" | "hard_cap";
  reason: string;
}

export interface ListValidationResult {
  operation: Operation;
  totalChecked: number;
  abnormalCount: number;
  rows: ListRowFinding[];
  /** Contextual combination totals that look abnormal (production only). */
  combinationFindings?: CombinationFinding[];
  combinationAbnormalCount?: number;
}

interface DateFilter {
  dateFrom?: string;
  dateTo?: string;
}

/** Load unreconciled, non-cancelled rows for an operation as check inputs. */
async function loadUnreconciledRows(
  operation: Operation,
  filter: DateFilter,
): Promise<{ id: number; raw: { rollWeights?: number[]; netWeight?: number; quantity?: number; gsm?: number | null } }[]> {
  const from = filter.dateFrom ?? null;
  const to = filter.dateTo ?? null;

  if (operation === "production") {
    const { rows } = await db.execute<{ id: number; rolls: number[] }>(sql`
      SELECT h.id AS id,
             array_agg(d.roll_weight::float8) AS rolls
      FROM daily_production_header h
      JOIN daily_production_detail d ON d.header_id = h.id
      WHERE h.status <> 'cancelled' AND h.reconciled = false
        AND (${from}::date IS NULL OR h.production_date >= ${from}::date)
        AND (${to}::date   IS NULL OR h.production_date <= ${to}::date)
      GROUP BY h.id`);
    return rows.map((r) => ({ id: r.id, raw: { rollWeights: (r.rolls ?? []).map(Number) } }));
  }

  if (operation === "receipt") {
    const { rows } = await db.execute<{ id: number; net_weight: number; quantity: number }>(sql`
      SELECT d.id AS id, d.net_weight::float8 AS net_weight, d.quantity::float8 AS quantity
      FROM yarn_receipt_detail d
      JOIN yarn_receipt_header h ON h.id = d.header_id
      WHERE h.status <> 'cancelled' AND h.reconciled = false
        AND (${from}::date IS NULL OR h.receipt_date >= ${from}::date)
        AND (${to}::date   IS NULL OR h.receipt_date <= ${to}::date)`);
    return rows.map((r) => ({
      id: r.id,
      raw: { netWeight: Number(r.net_weight), quantity: Number(r.quantity) },
    }));
  }

  // delivery
  const { rows } = await db.execute<{ id: number; net_weight: number; quantity: number; gsm: number | null }>(sql`
    SELECT id, net_weight::float8 AS net_weight, quantity::float8 AS quantity, gsm
    FROM daily_delivery
    WHERE status <> 'cancelled' AND reconciled = false
      AND (${from}::date IS NULL OR delivery_date >= ${from}::date)
      AND (${to}::date   IS NULL OR delivery_date <= ${to}::date)`);
  return rows.map((r) => ({
    id: r.id,
    raw: { netWeight: Number(r.net_weight), quantity: Number(r.quantity), gsm: r.gsm == null ? null : Number(r.gsm) },
  }));
}

/**
 * Evaluate the 26 contextual total-weight combinations for a single production
 * date. For each combination we pull the day's per-key totals (unreconciled
 * only) and check each against that combination's learned baseline. Returns
 * every flagged key instance. Production-only; requires a concrete date.
 */
async function evaluateCombinations(
  date: string,
  baselines: BaselineMap,
): Promise<CombinationFinding[]> {
  const out: CombinationFinding[] = [];

  for (const dims of TOTAL_WEIGHT_COMBINATIONS) {
    const field = comboField(dims);
    const baseline = baselines[field as PlausibilityField];
    const keyDims = canonical(dims);

    const result = await db.execute<Record<string, unknown>>(
      comboTotalsForDateSQL(dims, date),
    );

    for (const r of result.rows) {
      const total = Number(r.total);
      if (!Number.isFinite(total) || total <= 0) continue;
      const labels = keyDims.map((_, i) => String(r[`label_${i}`] ?? ""));
      const context = labels.filter(Boolean).join(", ") || "all entries";
      const w = checkValue(field, `Total weight (${comboLabel(dims)})`, total, TOTAL_WEIGHT_HARD_CAP, baseline, context);
      if (w) {
        out.push({
          field,
          combination: comboLabel(dims),
          context,
          value: w.value,
          expectedLow: w.expectedLow,
          expectedHigh: w.expectedHigh,
          source: w.source,
          reason: w.reason,
        });
      }
    }
  }

  return out;
}

/**
 * Evaluate the contextual net-total combinations for receipt/delivery on a
 * single date. For each combination we pull that day's per-key net-weight
 * totals (unreconciled only) and check each against the combination's learned
 * baseline. Returns every flagged key instance. Requires a concrete date.
 */
async function evaluateNetCombinations(
  operation: ComboOperation,
  date: string,
  baselines: BaselineMap,
): Promise<CombinationFinding[]> {
  const out: CombinationFinding[] = [];

  for (const dims of NET_TOTAL_COMBINATIONS[operation]) {
    const field = netComboField(operation, dims);
    const baseline = baselines[field as PlausibilityField];
    const keyDims = netCanonical(operation, dims);

    const result = await db.execute<Record<string, unknown>>(
      netComboTotalsForDateSQL(operation, dims, date),
    );

    for (const r of result.rows) {
      const total = Number(r.total);
      if (!Number.isFinite(total) || total <= 0) continue;
      const labels = keyDims.map((_, i) => String(r[`label_${i}`] ?? ""));
      const context = labels.filter(Boolean).join(", ") || "all entries";
      const w = checkValue(
        field,
        `Net total (${netComboLabel(operation, dims)})`,
        total,
        NET_TOTAL_HARD_CAP,
        baseline,
        context,
      );
      if (w) {
        out.push({
          field,
          combination: netComboLabel(operation, dims),
          context,
          value: w.value,
          expectedLow: w.expectedLow,
          expectedHigh: w.expectedHigh,
          source: w.source,
          reason: w.reason,
        });
      }
    }
  }

  return out;
}

export async function validateList(
  operation: Operation,
  filter: DateFilter = {},
): Promise<ListValidationResult> {
  const baselines = await loadBaselines(operation);
  const inputs = await loadUnreconciledRows(operation, filter);

  const findings: ListRowFinding[] = [];
  for (const { id, raw } of inputs) {
    const warnings = checkEntry(operation, raw, baselines);
    if (warnings.length > 0) findings.push({ id, warnings });
  }

  const result: ListValidationResult = {
    operation,
    totalChecked: inputs.length,
    abnormalCount: findings.length,
    rows: findings,
  };

  // Contextual combination totals — only for a concrete single day (the
  // listing always scopes to one date).
  const singleDay = filter.dateFrom && filter.dateFrom === filter.dateTo;
  if (singleDay) {
    if (operation === "production") {
      const combinationFindings = await evaluateCombinations(filter.dateFrom!, baselines);
      result.combinationFindings = combinationFindings;
      result.combinationAbnormalCount = combinationFindings.length;
    } else if (operation === "receipt" || operation === "delivery") {
      const combinationFindings = await evaluateNetCombinations(
        operation as ComboOperation,
        filter.dateFrom!,
        baselines,
      );
      result.combinationFindings = combinationFindings;
      result.combinationAbnormalCount = combinationFindings.length;
    }
  }

  return result;
}
