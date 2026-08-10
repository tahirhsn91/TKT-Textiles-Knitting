// ─── Plausibility client ───────────────────────────────────────────────────
// Thin wrappers around the warn-only validation API. All calls are best-effort:
// if validation is unavailable the caller should proceed with the save rather
// than block the operator on a non-critical check.

export type PlausibilityOperation = "production" | "receipt" | "delivery";

export type PlausibilityField =
  | "roll_weight" | "net_weight" | "quantity" | "gsm" | "wt_per_bag" | "wt_per_roll";

export interface PlausibilityWarning {
  field: PlausibilityField;
  label: string;
  value: number;
  expectedLow: number;
  expectedHigh: number;
  source: "learned" | "hard_cap";
  reason: string;
}

export interface EntryValues {
  rollWeights?: number[];
  netWeight?: number;
  quantity?: number;
  gsm?: number | null;
}

const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");

/**
 * Validate a single entry the operator is about to save. Returns warnings
 * (possibly empty). On any network/parse error returns an empty list so the
 * save is never blocked by a validation outage.
 */
export async function validateDailyEntry(
  operation: PlausibilityOperation,
  values: EntryValues,
): Promise<PlausibilityWarning[]> {
  try {
    const res = await fetch(`${BASE}/api/validate/daily-entry`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ operation, values }),
    });
    if (!res.ok) return [];
    const json = (await res.json()) as { warnings?: PlausibilityWarning[] };
    return json.warnings ?? [];
  } catch {
    return [];
  }
}

export interface ListFinding {
  id: number;
  warnings: PlausibilityWarning[];
}

export interface ListValidationResult {
  operation: PlausibilityOperation;
  totalChecked: number;
  abnormalCount: number;
  rows: ListFinding[];
}

/** Validate a listing's unreconciled rows for the top-of-page banner. */
export async function validateDailyList(
  operation: PlausibilityOperation,
  opts: { dateFrom?: string; dateTo?: string } = {},
): Promise<ListValidationResult | null> {
  try {
    const res = await fetch(`${BASE}/api/validate/daily-list`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ operation, ...opts }),
    });
    if (!res.ok) return null;
    return (await res.json()) as ListValidationResult;
  } catch {
    return null;
  }
}

export type FeedbackOutcome = "confirmed_anyway" | "corrected";

export interface FeedbackItem {
  operation: PlausibilityOperation;
  field: PlausibilityField;
  enteredValue: number;
  expectedLow?: number | null;
  expectedHigh?: number | null;
  outcome: FeedbackOutcome;
  createdBy?: string | null;
}

/** Record what the operator did with a warned value. Fire-and-forget. */
export async function recordPlausibilityFeedback(items: FeedbackItem[]): Promise<void> {
  if (items.length === 0) return;
  try {
    await fetch(`${BASE}/api/plausibility/feedback`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ items }),
    });
  } catch {
    // non-critical; ignore
  }
}

/** Build feedback items from a set of warnings + the chosen outcome. */
export function warningsToFeedback(
  operation: PlausibilityOperation,
  warnings: PlausibilityWarning[],
  outcome: FeedbackOutcome,
  createdBy?: string | null,
): FeedbackItem[] {
  return warnings.map((w) => ({
    operation,
    field: w.field,
    enteredValue: w.value,
    expectedLow: w.expectedLow,
    expectedHigh: w.expectedHigh,
    outcome,
    createdBy: createdBy ?? null,
  }));
}
