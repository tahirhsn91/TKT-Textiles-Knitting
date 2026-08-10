// ─── Robust statistics ─────────────────────────────────────────────────────
// Pure, dependency-free helpers. Kept separate from the DB layer so they can be
// unit-tested in isolation and reused by both baseline computation and any
// ad-hoc analysis.
//
// Robust estimators (median / IQR / MAD) are used throughout rather than
// mean / stddev because the historical data already contains gross outliers
// (e.g. a 2,181 kg "roll" against a ~30 kg norm). The median and IQR are
// unaffected by a handful of extreme values, so bounds derived from them stay
// correct even before any bad data is cleaned.

/** Sorted-array quantile via linear interpolation (type-7, the R default). */
export function quantileSorted(sorted: number[], q: number): number {
  const n = sorted.length;
  if (n === 0) return NaN;
  if (n === 1) return sorted[0];
  const pos = (n - 1) * q;
  const lo = Math.floor(pos);
  const hi = Math.ceil(pos);
  if (lo === hi) return sorted[lo];
  const frac = pos - lo;
  return sorted[lo] * (1 - frac) + sorted[hi] * frac;
}

export function median(values: number[]): number {
  if (values.length === 0) return NaN;
  const sorted = [...values].sort((a, b) => a - b);
  return quantileSorted(sorted, 0.5);
}

/** Interquartile range: Q3 − Q1. Zero when ≥75% of values are identical. */
export function iqr(values: number[]): number {
  if (values.length === 0) return NaN;
  const sorted = [...values].sort((a, b) => a - b);
  return quantileSorted(sorted, 0.75) - quantileSorted(sorted, 0.25);
}

/**
 * Median absolute deviation. Scaled by 1.4826 so that, for normally
 * distributed data, MAD ≈ standard deviation — which lets it stand in for the
 * spread when the IQR collapses to zero (highly repeated values).
 */
export function mad(values: number[]): number {
  if (values.length === 0) return NaN;
  const med = median(values);
  const deviations = values.map((v) => Math.abs(v - med));
  return 1.4826 * median(deviations);
}

export interface RobustSummary {
  median: number;
  iqr: number;
  mad: number;
  sampleCount: number;
}

export function robustSummary(values: number[]): RobustSummary {
  const finite = values.filter((v) => Number.isFinite(v));
  return {
    median: median(finite),
    iqr: iqr(finite),
    mad: mad(finite),
    sampleCount: finite.length,
  };
}

export interface Bounds {
  lower: number;
  upper: number;
}

/**
 * Warn bounds from a robust summary: median ± k · spread.
 *
 * Spread is the IQR when it is meaningfully non-zero, otherwise the MAD
 * (which survives heavily-repeated values). If both collapse to zero — every
 * historical value identical — there is no learned spread to speak of, so the
 * bounds degenerate to the median itself and the caller falls back to the
 * hard sanity caps.
 *
 * The lower bound is clamped at zero: every field the validator watches is a
 * physical weight, count or GSM, none of which can be negative.
 */
export function boundsFromSummary(s: RobustSummary, k: number): Bounds {
  const spread = s.iqr > 0 ? s.iqr : s.mad;
  if (!Number.isFinite(spread) || spread <= 0) {
    return { lower: s.median, upper: s.median };
  }
  return {
    lower: Math.max(0, s.median - k * spread),
    upper: s.median + k * spread,
  };
}
