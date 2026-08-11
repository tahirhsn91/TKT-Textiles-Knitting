/**
 * Query hook for the Machine Production Analytics endpoint (issue #112).
 * Returns per-machine fabric production since each machine's needle/sinker
 * change date, computed from Fabric Production transactions.
 */
import {
  useQuery,
  type UseQueryOptions,
  type QueryKey,
} from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import type { ErrorType } from "@/vendor/api-client-react/custom-fetch";

export type MachineAnalyticsBaseline = "needle" | "sinker";

/** One machine's production-since-change summary. */
export interface MachineAnalyticsRow {
  machineId: number;
  machineNumber: string;
  machineName: string | null;
  baseline: MachineAnalyticsBaseline;
  changeDate: string | null;
  daysSinceChange: number | null;
  humanizedDuration: string | null;
  totalKg: number;
  totalRolls: number;
  transactionCount: number;
  kgPerRoll: number;
}

export interface MachineAnalyticsResponse {
  baseline: MachineAnalyticsBaseline;
  computedTo: string;
  machineCount: number;
  excludedCount: number;
  rows: MachineAnalyticsRow[];
}

export const getMachineAnalyticsQueryKey = (baseline: MachineAnalyticsBaseline) =>
  [`/api/machine-analytics`, { baseline }] as const;

export function useMachineAnalytics(
  baseline: MachineAnalyticsBaseline,
  options?: { query?: Partial<UseQueryOptions<MachineAnalyticsResponse, ErrorType<unknown>>> },
) {
  return useQuery<MachineAnalyticsResponse, ErrorType<unknown>>({
    queryKey: getMachineAnalyticsQueryKey(baseline) as QueryKey,
    queryFn: () =>
      customFetch<MachineAnalyticsResponse>(
        `/api/machine-analytics?baseline=${encodeURIComponent(baseline)}`,
      ),
    ...options?.query,
  });
}
