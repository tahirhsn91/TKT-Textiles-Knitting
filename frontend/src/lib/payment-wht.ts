/**
 * Payment WHT derivation helpers.
 *
 * Payments are recorded as a NET amount received plus a withholding-tax (WHT)
 * RATE (%). The tax is a percentage OF THE GROSS, so:
 *
 *   rate          e.g. 0.01 (1%)
 *   gross = net / (1 - rate)
 *   tax   = gross * rate        (rounded to 2 dp)
 *   gross = net + tax           (net + rounded tax, so the three reconcile)
 *
 * The default WHT rate is 1%. The net→gross relationship is the one requested
 * for the "Record Payment" popup (outstanding reduces by GROSS).
 */

/** Default WHT rate, as a fraction of gross. */
export const DEFAULT_WHT_RATE = 0.01; // 1%

/** Round a currency amount to 2 decimal places (banker-safe enough for this UI). */
export function round2(n: number): number {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

export interface DerivedPayment {
  /** Tax deduction amount (currency), rounded to 2 dp. */
  tax: number;
  /** Gross amount = net + rounded tax (so net + tax = gross exactly). */
  gross: number;
  /** Effective rate actually applied, as a fraction (e.g. 0.01). */
  rate: number;
}

/**
 * Derive gross + tax from a NET received amount and a WHT rate.
 *
 * Gross is computed from the net and rate; tax is that rate applied to gross,
 * rounded to 2 dp; gross is then re-anchored to net + rounded tax so the three
 * always reconcile for display/storage.
 *
 * @param net        the net amount received (>= 0)
 * @param rate       WHT rate as a fraction of gross (0 <= rate < 1)
 */
export function derivePayment(net: number, rate: number): DerivedPayment {
  const safeRate = Number.isFinite(rate) ? Math.min(Math.max(rate, 0), 0.999999) : DEFAULT_WHT_RATE;
  // gross = net / (1 - rate); guard against rate >= 1 (divide by ~0).
  const grossFromNet = safeRate < 1 ? net / (1 - safeRate) : Infinity;
  const tax = round2(grossFromNet * safeRate);
  const gross = round2(net + tax);
  return { tax, gross, rate: safeRate };
}

/**
 * Given a remaining GROSS balance, return the maximum NET that can be received
 * before the payment would overpay: maxNet = balance * (1 - rate).
 */
export function maxNetForBalance(balance: number, rate: number): number {
  const safeRate = Number.isFinite(rate) ? Math.min(Math.max(rate, 0), 0.999999) : DEFAULT_WHT_RATE;
  return round2(balance * (1 - safeRate));
}
