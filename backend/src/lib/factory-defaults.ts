/**
 * Factory / machine-spec defaults (issue #6).
 *
 * These were previously hardcoded inline in the machine create/update route
 * handlers. They are now named constants in one shared place so a change is a
 * single edit rather than scattered string literals. This is intentionally a
 * code constant (not DB config) per the product decision — update here, not in
 * a settings table.
 */

/** Default needle brand applied when a machine is created without one. */
export const DEFAULT_NEEDLE_BRAND = "Sigma";

/** Default sinker brand applied when a machine is created without one. */
export const DEFAULT_SINKER_BRAND = "Kohala";

/** Default making rate (per the factory's fabric/knitting rate). */
export const DEFAULT_MAKING_RATE = "3.75";

/**
 * Normalise an incoming making rate: keep a provided value (normalised to a
 * string), otherwise fall back to the default.
 */
export function normaliseMakingRate(rate: unknown): string {
  if (rate != null && rate !== "") {
    return String(parseFloat(String(rate)));
  }
  return DEFAULT_MAKING_RATE;
}
