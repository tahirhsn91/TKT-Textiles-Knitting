// ─── Total-weight validation for production (A + contextual combinations) ───
//
// Two kinds of check live here, both over an entry's *total* weight (the sum of
// its roll weights) rather than an individual roll:
//
//   A) total_weight            — the per-entry total, global baseline. Runs at
//                                insert-time in the production dialog.
//   B) 26 contextual combos    — the total aggregated per a combination of the
//                                five production dimensions (date, shift,
//                                machine, employee, party). Listing-time only.
//
// Every combination is stored as a normal plausibility_baseline row whose
// `field` encodes the dimensions, e.g. "total_weight@date+shift+machine". No
// schema change — the existing (operation, field) key carries the context.
//
// Windowing (agreed):
//   • Baselines are learned over a trailing 30-day window.
//   • Combos WITHOUT a date dimension aggregate per-day first, then learn the
//     distribution of those daily per-key totals across the window.
//   • Combos WITH a date dimension already are a single day's aggregate; the
//     window supplies the distribution of same-shaped daily totals.

import { sql, type SQL } from "drizzle-orm";
import { HardCap } from "./config.js";

/** The five production dimensions that can form a combination key. */
export type Dimension = "date" | "shift" | "machine" | "employee" | "party";

const DIM_COLUMN: Record<Dimension, string> = {
  date: "h.production_date",
  shift: "h.shift",
  machine: "h.machine_id",
  employee: "h.employee_id",
  party: "h.party_id",
};

const DIM_LABEL: Record<Dimension, string> = {
  date: "Date",
  shift: "Shift",
  machine: "Machine",
  employee: "Employee",
  party: "Party",
};

/**
 * The 26 combinations requested for issue #106 (option C). Order within each
 * tuple is canonical: date, shift, machine, employee, party — so the encoded
 * field string is stable regardless of how the combo is written here.
 */
export const TOTAL_WEIGHT_COMBINATIONS: Dimension[][] = [
  ["date"],
  ["shift"],
  ["machine"],
  ["employee"],
  ["date", "shift"],
  ["date", "machine"],
  ["date", "employee"],
  ["shift", "machine"],
  ["shift", "employee"],
  ["machine", "employee"],
  ["machine", "party"],
  ["date", "shift", "machine"],
  ["date", "shift", "employee"],
  ["date", "machine", "employee"],
  ["date", "machine", "party"],
  ["date", "employee", "party"],
  ["shift", "machine", "employee"],
  ["shift", "machine", "party"],
  ["shift", "employee", "party"],
  ["machine", "employee", "party"],
  ["date", "shift", "machine", "employee"],
  ["date", "shift", "machine", "party"],
  ["date", "shift", "employee", "party"],
  ["date", "machine", "employee", "party"],
  ["shift", "machine", "employee", "party"],
  ["date", "shift", "machine", "employee", "party"],
];

const CANONICAL_ORDER: Dimension[] = ["date", "shift", "machine", "employee", "party"];

/** Sort a combination into canonical dimension order. */
export function canonical(dims: Dimension[]): Dimension[] {
  return CANONICAL_ORDER.filter((d) => dims.includes(d));
}

/** The plausibility_baseline `field` string for a combination, e.g.
 *  ["machine","shift"] → "total_weight@shift+machine". */
export function comboField(dims: Dimension[]): string {
  return `total_weight@${canonical(dims).join("+")}`;
}

/** The global per-entry total-weight field (combination A). */
export const TOTAL_WEIGHT_FIELD = "total_weight";

/** Human label for a combination, e.g. "Shift + Machine". */
export function comboLabel(dims: Dimension[]): string {
  return canonical(dims).map((d) => DIM_LABEL[d]).join(" + ");
}

/** Parse a field string back to its dimensions (empty for the global field). */
export function parseComboField(field: string): Dimension[] | null {
  if (field === TOTAL_WEIGHT_FIELD) return [];
  const m = field.match(/^total_weight@(.+)$/);
  if (!m) return null;
  const dims = m[1].split("+") as Dimension[];
  return dims.every((d) => (CANONICAL_ORDER as string[]).includes(d)) ? dims : null;
}

/** True for any total-weight field (global or combination). */
export function isTotalWeightField(field: string): boolean {
  return field === TOTAL_WEIGHT_FIELD || /^total_weight@/.test(field);
}

/**
 * Hard sanity cap for a total-weight series. A single production entry's total
 * is bounded generously; a per-combination daily aggregate can legitimately be
 * larger (several entries), so combination caps scale with the number of
 * dimensions only loosely — we keep one generous cap and lean on the learned
 * band for context. Values past this are physically implausible regardless.
 */
export const TOTAL_WEIGHT_HARD_CAP: HardCap = { min: 0.5, max: 20_000 };

// ─── Series SQL builders ───────────────────────────────────────────────────
// All series are restricted to non-cancelled headers within the trailing
// window. Roll weights are summed per header first, so a "total" is always the
// sum of that header's rolls.

/** WINDOW_DAYS trailing days for baseline learning. */
export const WINDOW_DAYS = 30;

/**
 * Series for combination A — one value per production entry (header total),
 * across the trailing window. This is the global per-entry total distribution.
 */
export function perEntryTotalSeriesSQL(windowDays = WINDOW_DAYS): SQL {
  return sql`
    SELECT t.total::float8 AS v
    FROM (
      SELECT h.id, SUM(d.roll_weight) AS total
      FROM daily_production_header h
      JOIN daily_production_detail d ON d.header_id = h.id
      WHERE h.status <> 'cancelled'
        AND h.production_date >= (CURRENT_DATE - ${windowDays}::int)
      GROUP BY h.id
    ) t
    WHERE t.total > 0`;
}

/**
 * Series for a combination — the distribution of per-key DAILY totals across
 * the window. Even date-less combos are aggregated per production_date first
 * (so "Machine" means "that machine's total for a given day"), which keeps the
 * learned quantity a *daily* total regardless of whether Date is a grouping
 * dimension. When Date IS a dimension the per-day grouping is implied by the
 * key itself.
 */
export function comboDailyTotalSeriesSQL(dims: Dimension[], windowDays = WINDOW_DAYS): SQL {
  const keyDims = canonical(dims);
  // Always group by production_date so the learned value is a daily total,
  // plus every dimension in the combo. (production_date may appear twice in
  // intent when date is a dim, but listing it once is sufficient and correct.)
  const groupCols = new Set<string>(["h.production_date"]);
  for (const d of keyDims) groupCols.add(DIM_COLUMN[d]);
  const groupList = sql.raw([...groupCols].join(", "));

  return sql`
    SELECT t.total::float8 AS v
    FROM (
      SELECT ${sql.raw([...groupCols].join(", "))}, SUM(d.roll_weight) AS total
      FROM daily_production_header h
      JOIN daily_production_detail d ON d.header_id = h.id
      WHERE h.status <> 'cancelled'
        AND h.production_date >= (CURRENT_DATE - ${windowDays}::int)
      GROUP BY ${groupList}
    ) t
    WHERE t.total > 0`;
}

/**
 * For listing-time evaluation: the per-key DAILY totals for a SPECIFIC date,
 * for one combination. Only unreconciled, non-cancelled rows are counted, so
 * the totals reflect what is still editable. Returns one row per distinct key
 * value present that day, with a human label for the key.
 */
// Readable label expressions per dimension, for building the human "context"
// string of a flagged combination (e.g. "Machine 25, Morning").
const DIM_LABEL_SQL: Record<Dimension, string> = {
  date: "h.production_date::text",
  shift: "h.shift",
  machine: "COALESCE(mm.machine_number, 'Machine ' || h.machine_id::text)",
  employee: "COALESCE(em.name, 'Employee ' || h.employee_id::text)",
  party: "COALESCE(pm.name, 'Party ' || h.party_id::text)",
};

export interface ComboDateRow {
  total: number;
  entries: number;
  labels: string[];
}

/**
 * Per-key daily totals for a SPECIFIC date and one combination, with readable
 * label columns for each dimension so the caller can compose a context string.
 * Only unreconciled, non-cancelled rows are counted. The ISO `date` is bound
 * directly into the query.
 */
export function comboTotalsForDateSQL(dims: Dimension[], date: string): SQL {
  const keyDims = canonical(dims);
  const groupCols = new Set<string>(["h.production_date"]);
  for (const d of keyDims) groupCols.add(DIM_COLUMN[d]);
  // Label expressions must also appear in GROUP BY (they are non-aggregated),
  // so group by both the key columns and every label expression used.
  for (const d of keyDims) groupCols.add(DIM_LABEL_SQL[d]);
  const groupList = sql.raw([...groupCols].join(", "));

  // Emit one labelled column per dimension in the combo, in canonical order,
  // aliased label_0, label_1, ... so results can be read positionally.
  const labelSelects = keyDims
    .map((d, i) => `${DIM_LABEL_SQL[d]} AS label_${i}`)
    .join(", ");
  const labelPrefix = labelSelects ? sql.raw(labelSelects + ", ") : sql.raw("");

  // Master joins only added when the relevant dimension is present.
  const joinMachine = keyDims.includes("machine")
    ? sql.raw("LEFT JOIN machine_master mm ON mm.id = h.machine_id") : sql.raw("");
  const joinEmployee = keyDims.includes("employee")
    ? sql.raw("LEFT JOIN employee_master em ON em.id = h.employee_id") : sql.raw("");
  const joinParty = keyDims.includes("party")
    ? sql.raw("LEFT JOIN party_master pm ON pm.id = h.party_id") : sql.raw("");

  return sql`
    SELECT ${labelPrefix}SUM(d.roll_weight)::float8 AS total, COUNT(DISTINCT h.id)::int AS entries
    FROM daily_production_header h
    JOIN daily_production_detail d ON d.header_id = h.id
    ${joinMachine}
    ${joinEmployee}
    ${joinParty}
    WHERE h.status <> 'cancelled'
      AND h.reconciled = false
      AND h.production_date = ${date}::date
    GROUP BY ${groupList}`;
}
