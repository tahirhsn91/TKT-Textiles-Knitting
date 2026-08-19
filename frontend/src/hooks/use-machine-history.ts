/**
 * Hand-written query hooks for the machine history audit trail.
 *
 * Machine history is a read-only timeline of machine_master writes (create /
 * update / delete snapshots). There are no mutations here — rows are written
 * only by the backend CRUD hook (and the initial seed backfill). Mirrors the
 * use-machine-maintenance conventions.
 */
import { useQuery, type UseQueryOptions, type QueryKey } from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import type { ErrorType } from "@/vendor/api-client-react/custom-fetch";

/** One machine_history row (newest-first from the API). */
export interface MachineHistoryRow {
  id: number;
  machineId: number | null;
  machineNumber: string;
  name: string;
  makingRate: string | null;
  needleChangeDate: string | null;
  needleBrand: string | null;
  sinkerChangeDate: string | null;
  sinkerBrand: string | null;
  action: "created" | "updated" | "deleted";
  changedBy: string;
  changedAt: string;
}

export const machineHistoryQueryKey = "/api/masters/machine-history" as const;

/** Full machine history timeline, newest first. */
export function useMachineHistory(
  options?: { query?: Partial<UseQueryOptions<MachineHistoryRow[], ErrorType<unknown>>> },
) {
  return useQuery<MachineHistoryRow[], ErrorType<unknown>>({
    queryKey: [machineHistoryQueryKey] as unknown as QueryKey,
    queryFn: ({ signal }) => customFetch<MachineHistoryRow[]>(machineHistoryQueryKey, { method: "GET", signal }),
    staleTime: 30_000,
    ...options?.query,
  });
}
