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
  type BaselineEntry,
  type BaselineMap,
  type PlausibilityWarning,
} from "./check.js";

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

/** Recompute and upsert the baseline for every field of one operation. */
export async function retrainOperation(operation: Operation): Promise<void> {
  for (const field of OPERATION_FIELDS[operation]) {
    const values = await fetchSeries(operation, field);
    if (values.length === 0) continue;

    const summary = robustSummary(values);
    const bounds = boundsFromSummary(summary, K);

    await db
      .insert(plausibilityBaselineTable)
      .values({
        operation,
        field,
        median: String(summary.median),
        iqr: String(summary.iqr),
        mad: String(summary.mad),
        lowerBound: String(bounds.lower),
        upperBound: String(bounds.upper),
        sampleCount: summary.sampleCount,
        computedAt: new Date(),
      })
      .onConflictDoUpdate({
        target: [plausibilityBaselineTable.operation, plausibilityBaselineTable.field],
        set: {
          median: String(summary.median),
          iqr: String(summary.iqr),
          mad: String(summary.mad),
          lowerBound: String(bounds.lower),
          upperBound: String(bounds.upper),
          sampleCount: summary.sampleCount,
          computedAt: new Date(),
        },
      });
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
  return checkEntry(operation, raw, baselines);
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

export interface ListValidationResult {
  operation: Operation;
  totalChecked: number;
  abnormalCount: number;
  rows: ListRowFinding[];
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

  return {
    operation,
    totalChecked: inputs.length,
    abnormalCount: findings.length,
    rows: findings,
  };
}
