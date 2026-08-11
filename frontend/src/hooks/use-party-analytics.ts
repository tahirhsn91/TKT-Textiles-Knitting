/**
 * Query hook for the Party Analytics endpoint (issue #115).
 * Fabric Production vs Fabric Delivery for a party + month + year.
 */
import {
  useQuery,
  type UseQueryOptions,
  type QueryKey,
} from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import type { ErrorType } from "@/vendor/api-client-react/custom-fetch";
import { useListPartyMaster } from "@workspace/api-client-react";

export interface KgRolls {
  kg: number;
  rolls: number;
}

export interface PartyAnalyticsResponse {
  party: { id: number; name: string; code: string } | null;
  window: { month: number; year: number; from: string; to: string; isCurrentMonth: boolean };
  totals: {
    production: KgRolls;
    delivery: KgRolls;
  };
  byParty: {
    partyId: number;
    partyName: string;
    production: KgRolls;
    delivery: KgRolls;
  }[];
  fabricBreakdown: {
    type: string;
    productionKg: number;
    productionRolls: number;
    deliveryKg: number;
    deliveryRolls: number;
  }[];
  dailyTrend: { date: string; productionKg: number; deliveryKg: number }[];
}

export interface PartyAnalyticsFilters {
  month: number;
  year: number;
  partyId?: number | null;
}

export const getPartyAnalyticsQueryKey = (f: PartyAnalyticsFilters) =>
  [`/api/party-analytics`, f] as const;

export function usePartyAnalytics(
  filters: PartyAnalyticsFilters,
  options?: { query?: Partial<UseQueryOptions<PartyAnalyticsResponse, ErrorType<unknown>>> },
) {
  const params = new URLSearchParams({
    month: String(filters.month),
    year: String(filters.year),
  });
  if (filters.partyId != null) params.set("partyId", String(filters.partyId));

  return useQuery<PartyAnalyticsResponse, ErrorType<unknown>>({
    queryKey: getPartyAnalyticsQueryKey(filters) as QueryKey,
    queryFn: () => customFetch<PartyAnalyticsResponse>(`/api/party-analytics?${params.toString()}`),
    ...options?.query,
  });
}

/** Available years, from a floor to the current year (future years disabled). */
export function availableYears(floor = 2020): number[] {
  const current = new Date().getFullYear();
  const years: number[] = [];
  for (let y = current; y >= floor; y--) years.push(y);
  return years;
}

/** Parties list — for the "All parties" + each-party filter options. */
export function usePartyOptions() {
  const { data } = useListPartyMaster();
  return (data ?? []) as { id: number; name: string; code: string }[];
}
