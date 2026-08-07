/**
 * Display rounding for all numeric values across the app (weights, totals,
 * percentages). Change it here and every screen follows — never hardcode
 * a digit in a page.
 */
export const NUM_DECIMALS = 2;

/**
 * Round a numeric string (or number) to `digits` decimals, returning a string
 * ready for a number input / display. Empty or non-numeric values pass through
 * unchanged so an in-progress field isn't clobbered.
 */
export function roundInput(value: string | number | null | undefined, digits: number): string {
  if (value === null || value === undefined || value === "") return "";
  const n = Number(value);
  if (!Number.isFinite(n)) return String(value);
  // Round and strip trailing zeros so `5.60` renders as `5.6` for qty inputs.
  return String(Number(n.toFixed(digits)));
}
