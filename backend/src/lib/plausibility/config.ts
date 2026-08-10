// ─── Plausibility configuration ────────────────────────────────────────────
// Central definition of what the validator watches and the constants that
// govern it. Bounds themselves are learned dynamically; the values here are
// the sensitivity dial (k), the trust threshold (MIN_SAMPLE_COUNT) and the
// physical hard caps used as a cold-start backstop.

/** The three daily operations. */
export type Operation = "production" | "receipt" | "delivery";

/** Every numeric field (direct or derived) the validator checks. */
export type PlausibilityField =
  | "roll_weight"
  | "net_weight"
  | "quantity"
  | "gsm"
  | "wt_per_bag"
  | "wt_per_roll";

/**
 * Sensitivity of the learned band: a value is flagged when it falls outside
 * median ± k · spread. k = 3 is deliberately conservative — it flags only
 * clearly-abnormal values and keeps false alarms low.
 */
export const K = 3;

/**
 * Below this many historical samples the learned band is not yet trustworthy,
 * so the check falls back to the hard sanity caps only.
 */
export const MIN_SAMPLE_COUNT = 20;

/**
 * Physical sanity caps per field. These are NOT the normal-operating range —
 * they are the outer bounds of what is physically possible, used as a backstop
 * when history is thin. A knit roll over ~500 kg, a bag over ~150 kg, etc. is
 * almost certainly a data-entry error regardless of what history says.
 * `min` is the smallest plausible positive value; `max` the largest.
 */
export interface HardCap {
  min: number;
  max: number;
}

export const HARD_CAPS: Record<PlausibilityField, HardCap> = {
  // A single knit fabric roll. Normal ~25–35 kg; anything past 500 kg is a typo.
  roll_weight: { min: 0.5, max: 500 },
  // Net weight of a receipt/delivery line (can be a whole lot). Generous ceiling.
  net_weight: { min: 0.5, max: 50_000 },
  // Whole units — bags (receipt) or rolls (delivery).
  quantity: { min: 1, max: 5_000 },
  // Fabric GSM. Real knits sit roughly 80–600 g/m².
  gsm: { min: 40, max: 900 },
  // Weight of a single bag of yarn. Cotton bags run ~45 kg; cap well above.
  wt_per_bag: { min: 1, max: 200 },
  // Weight of a single fabric roll (delivery). Same physical object as above.
  wt_per_roll: { min: 0.5, max: 500 },
};

/** Which fields belong to which operation, and how derived fields are built. */
export const OPERATION_FIELDS: Record<Operation, PlausibilityField[]> = {
  production: ["roll_weight"],
  receipt: ["net_weight", "quantity", "wt_per_bag"],
  delivery: ["net_weight", "quantity", "gsm", "wt_per_roll"],
};

/** Human-facing field labels for warning messages. */
export const FIELD_LABELS: Record<PlausibilityField, string> = {
  roll_weight: "Roll weight",
  net_weight: "Net weight",
  quantity: "Quantity",
  gsm: "GSM",
  wt_per_bag: "Weight per bag",
  wt_per_roll: "Weight per roll",
};
