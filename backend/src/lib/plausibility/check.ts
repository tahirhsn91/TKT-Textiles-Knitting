// ─── The check (pure) ──────────────────────────────────────────────────────
// Given a learned baseline and a set of values, decide which values look
// abnormal. No I/O — the DB layer supplies the baseline and this returns
// structured warnings. Never throws; a missing/thin baseline simply falls back
// to the hard sanity caps.

import {
  FIELD_LABELS,
  HARD_CAPS,
  MIN_SAMPLE_COUNT,
  type Operation,
  type PlausibilityField,
} from "./config.js";

/** A single learned distribution row, as loaded from plausibility_baseline. */
export interface BaselineEntry {
  median: number;
  iqr: number;
  mad: number;
  lowerBound: number;
  upperBound: number;
  sampleCount: number;
}

export type BaselineMap = Partial<Record<PlausibilityField, BaselineEntry>>;

export interface PlausibilityWarning {
  field: PlausibilityField;
  label: string;
  value: number;
  expectedLow: number;
  expectedHigh: number;
  /** "learned" when the trained band flagged it, "hard_cap" for the backstop. */
  source: "learned" | "hard_cap";
  reason: string;
}

function round(n: number): number {
  return Math.round(n * 1000) / 1000;
}

/**
 * Check one field's value against its learned baseline (if trustworthy) and the
 * hard sanity caps. Returns a warning or null.
 */
export function checkField(
  field: PlausibilityField,
  value: number,
  baseline: BaselineEntry | undefined,
): PlausibilityWarning | null {
  if (!Number.isFinite(value)) return null;

  const label = FIELD_LABELS[field];
  const cap = HARD_CAPS[field];

  // Hard cap first — a physically impossible value is abnormal regardless of
  // what the learned band says (and catches the cold-start case directly).
  if (value < cap.min || value > cap.max) {
    return {
      field,
      label,
      value: round(value),
      expectedLow: cap.min,
      expectedHigh: cap.max,
      source: "hard_cap",
      reason: `${label} of ${round(value)} is outside the plausible range (${cap.min}–${cap.max}).`,
    };
  }

  // Learned band — only trusted once enough history has accumulated.
  if (baseline && baseline.sampleCount >= MIN_SAMPLE_COUNT) {
    const lo = baseline.lowerBound;
    const hi = baseline.upperBound;
    // Degenerate band (all history identical) carries no information.
    if (hi > lo && (value < lo || value > hi)) {
      return {
        field,
        label,
        value: round(value),
        expectedLow: round(lo),
        expectedHigh: round(hi),
        source: "learned",
        reason: `${label} of ${round(value)} is unusual — typical values run ${round(lo)}–${round(hi)}.`,
      };
    }
  }

  return null;
}

/**
 * Derive the full set of checkable field-values for an operation from its raw
 * entry, including the ratio fields. Non-positive/absent inputs for a ratio are
 * skipped rather than producing Infinity/NaN.
 */
export function deriveFieldValues(
  operation: Operation,
  raw: {
    rollWeights?: number[];
    netWeight?: number;
    quantity?: number;
    gsm?: number | null;
  },
): { field: PlausibilityField; value: number }[] {
  const out: { field: PlausibilityField; value: number }[] = [];

  if (operation === "production") {
    for (const w of raw.rollWeights ?? []) {
      if (Number.isFinite(w)) out.push({ field: "roll_weight", value: w });
    }
    return out;
  }

  if (raw.netWeight !== undefined && Number.isFinite(raw.netWeight)) {
    out.push({ field: "net_weight", value: raw.netWeight });
  }
  if (raw.quantity !== undefined && Number.isFinite(raw.quantity)) {
    out.push({ field: "quantity", value: raw.quantity });
  }

  if (operation === "receipt") {
    if (
      raw.netWeight !== undefined && raw.quantity !== undefined &&
      Number.isFinite(raw.netWeight) && (raw.quantity ?? 0) > 0
    ) {
      out.push({ field: "wt_per_bag", value: raw.netWeight / raw.quantity });
    }
  }

  if (operation === "delivery") {
    if (raw.gsm !== undefined && raw.gsm !== null && Number.isFinite(raw.gsm)) {
      out.push({ field: "gsm", value: raw.gsm });
    }
    if (
      raw.netWeight !== undefined && raw.quantity !== undefined &&
      Number.isFinite(raw.netWeight) && (raw.quantity ?? 0) > 0
    ) {
      out.push({ field: "wt_per_roll", value: raw.netWeight / raw.quantity });
    }
  }

  return out;
}

/**
 * Full check for one entry: derive its field-values and run each against the
 * baseline. Returns every warning found (possibly empty). Never throws.
 */
export function checkEntry(
  operation: Operation,
  raw: {
    rollWeights?: number[];
    netWeight?: number;
    quantity?: number;
    gsm?: number | null;
  },
  baselines: BaselineMap,
): PlausibilityWarning[] {
  const warnings: PlausibilityWarning[] = [];
  for (const { field, value } of deriveFieldValues(operation, raw)) {
    const w = checkField(field, value, baselines[field]);
    if (w) warnings.push(w);
  }
  return warnings;
}
