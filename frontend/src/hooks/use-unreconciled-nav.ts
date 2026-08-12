/**
 * Hook wrapping the prev/next unreconciled-date navigation endpoint.
 *
 * Powers the "previous / next date with unconciled data" buttons on the three
 * daily operations screens (Daily Production, Yarn Receipt, Daily Delivery).
 * Given the currently displayed date, resolves the nearest date strictly
 * before (`prev`) and strictly after (`next`) that holds at least one
 * unreconciled row (reconciled=false, status<>'cancelled'), or null when none
 * exists in that direction. The buttons are disabled for a null target and
 * while the query is loading (issue #120).
 */
import { useQuery, type UseQueryOptions, type QueryKey } from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import type { ErrorType } from "@/vendor/api-client-react/custom-fetch";

export type UnreconciledOperation = "production" | "receipt" | "delivery";

export interface UnreconciledNavDates {
  /** Nearest date strictly before the reference date with unconciled rows, or null. */
  prev: string | null;
  /** Nearest date strictly after the reference date with unconciled rows, or null. */
  next: string | null;
}

export const getUnreconciledNavQueryKey = (operation: UnreconciledOperation, date: string) =>
  [`/api/daily-ops/unreconciled/prev-next`, { operation, date }] as const;

export function useUnreconciledNav(
  operation: UnreconciledOperation,
  date: string,
  options?: { query?: Partial<UseQueryOptions<UnreconciledNavDates, ErrorType<unknown>>> },
) {
  return useQuery({
    queryKey: getUnreconciledNavQueryKey(operation, date) as unknown as QueryKey,
    queryFn: ({ signal }) =>
      customFetch<UnreconciledNavDates>(
        `/api/daily-ops/unreconciled/prev-next?operation=${encodeURIComponent(operation)}&date=${encodeURIComponent(date)}`,
        { method: "GET", signal },
      ),
    enabled: Boolean(date),
    staleTime: 30_000,
    ...options?.query,
  });
}
