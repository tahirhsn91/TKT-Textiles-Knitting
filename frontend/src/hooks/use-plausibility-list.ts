import { useQuery } from "@tanstack/react-query";
import {
  validateDailyList,
  type PlausibilityOperation,
  type ListValidationResult,
} from "@/lib/plausibility";

/**
 * Validates the unreconciled rows of a daily operation for a date range and
 * returns the abnormal-row summary that powers the listing-page banner.
 *
 * Warn-only and best-effort: a null result (validation unavailable) simply
 * renders no banner. Keyed on the date range so switching days refetches.
 */
export function usePlausibilityList(
  operation: PlausibilityOperation,
  opts: { dateFrom?: string; dateTo?: string; enabled?: boolean } = {},
) {
  const { dateFrom, dateTo, enabled = true } = opts;
  return useQuery<ListValidationResult | null>({
    queryKey: ["plausibility-list", operation, dateFrom ?? null, dateTo ?? null],
    queryFn: () => validateDailyList(operation, { dateFrom, dateTo }),
    enabled,
    staleTime: 30_000,
  });
}
