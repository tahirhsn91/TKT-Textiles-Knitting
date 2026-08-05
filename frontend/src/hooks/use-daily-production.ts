/**
 * Hand-written query/mutation hooks for the Daily Production resource.
 *
 * Every other resource in this app is consumed through
 * `@workspace/api-client-react`, generated from the backend's OpenAPI/zod
 * definitions. That generator hasn't been re-run against the
 * `/api/daily-production` routes yet, so these hooks are written by hand in
 * the same shape (query keys, options, mutation signatures) the generator
 * would produce. Once codegen is re-run, swap these imports for the
 * generated equivalents and delete this file — no call-site changes should
 * be needed.
 */
import {
  useQuery,
  useMutation,
  type UseQueryOptions,
  type QueryKey,
} from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import type { ErrorType } from "@/vendor/api-client-react/custom-fetch";

export type Shift = "Morning" | "Night";

/** One daily_production_header record. `id` is what the row's Edit and Delete
 *  actions act on — the list endpoint no longer groups across headers, so this
 *  is a real record rather than a rolled-up line. */
export interface DailyProductionSummaryRow {
  id: number;
  machineId: number;
  machineName: string | null;
  operatorId: number;
  operatorName: string | null;
  partyId: number;
  partyName: string | null;
  shift: Shift;
  remarks: string | null;
  createdBy: string;
  /** Consumed by a Fabric Production transaction. Permanent — never cleared. */
  reconciled: boolean;
  reconciledTransactionId: number | null;
  rollCount: number;
  totalProduction: string;
  /** True when at least one roll in this entry weighs more than 30 kg. */
  hasHeavyRoll: boolean;
}

/** A production entry available to reconcile, for the New Transaction screen. */
export interface UnreconciledProductionRow {
  id: number;
  productionDate: string;
  machineId: number;
  machineName: string | null;
  operatorId: number;
  operatorName: string | null;
  partyId: number;
  partyName: string | null;
  shift: Shift;
  rollCount: number;
  totalProduction: string;
}

export interface UnreconciledProductionResponse {
  productionDate: string;
  partyId: number;
  rows: UnreconciledProductionRow[];
}

export interface DailyProductionSummaryResponse {
  productionDate: string;
  rows: DailyProductionSummaryRow[];
  /** Aggregated totals for the whole month up to and including the selected date. */
  monthToDate: {
    rollCount: number;
    totalProduction: string;
  };
}

export interface DailyProductionDetailResponse {
  id: number;
  productionDate: string;
  machineId: number;
  operatorId: number;
  partyId: number;
  shift: Shift;
  status: string;
  remarks: string | null;
  createdBy: string;
  createdAt: string;
  updatedBy: string | null;
  updatedAt: string;
  rolls: { id: number; headerId: number; rollNumber: number; rollWeight: string; remarks: string | null }[];
}

export interface DailyProductionPayload {
  productionDate: string;
  machineId: number;
  operatorId: number;
  partyId: number;
  shift: Shift;
  remarks?: string | null;
  rolls: { rollWeight: string; remarks?: string | null }[];
}

// ─── Get production summary by date ─────────────────────────────────────────

export const getDailyProductionSummaryQueryKey = (date: string) =>
  [`/api/daily-production`, { date }] as const;

export function useGetDailyProductionSummary(
  date: string,
  options?: { query?: Partial<UseQueryOptions<DailyProductionSummaryResponse, ErrorType<unknown>>> },
) {
  return useQuery({
    queryKey: getDailyProductionSummaryQueryKey(date) as unknown as QueryKey,
    queryFn: ({ signal }) =>
      customFetch<DailyProductionSummaryResponse>(
        `/api/daily-production?date=${encodeURIComponent(date)}`,
        { method: "GET", signal },
      ),
    ...options?.query,
  });
}

// ─── Get one (future edit/drill-down use) ──────────────────────────────────

export const getGetDailyProductionQueryKey = (id: number) => [`/api/daily-production/${id}`] as const;

export function useGetDailyProduction(
  id: number,
  options?: { query?: Partial<UseQueryOptions<DailyProductionDetailResponse, ErrorType<unknown>>> },
) {
  return useQuery({
    queryKey: getGetDailyProductionQueryKey(id) as unknown as QueryKey,
    queryFn: ({ signal }) =>
      customFetch<DailyProductionDetailResponse>(`/api/daily-production/${id}`, { method: "GET", signal }),
    ...options?.query,
  });
}

// ─── Create ──────────────────────────────────────────────────────────────

export function useCreateDailyProduction() {
  return useMutation<DailyProductionDetailResponse, ErrorType<unknown>, { data: DailyProductionPayload & { createdBy: string } }>({
    mutationFn: ({ data }) =>
      customFetch<DailyProductionDetailResponse>(`/api/daily-production`, {
        method: "POST",
        body: JSON.stringify(data),
      }),
  });
}

// ─── Update (future support — not wired to current UI) ─────────────────────

export function useUpdateDailyProduction() {
  return useMutation<
    DailyProductionDetailResponse,
    ErrorType<unknown>,
    { id: number; data: DailyProductionPayload & { updatedBy: string } }
  >({
    mutationFn: ({ id, data }) =>
      customFetch<DailyProductionDetailResponse>(`/api/daily-production/${id}`, {
        method: "PUT",
        body: JSON.stringify(data),
      }),
  });
}

// ─── Unreconciled production for a date + party ───────────────────────────
// Drives the Fabric Production flow on the New Transaction screen. Disabled
// until both a date and a party are chosen, since the endpoint requires both.

export const getUnreconciledProductionQueryKey = (date: string, partyId: number | null) =>
  [`/api/daily-production/unreconciled`, { date, partyId }] as const;

export function useUnreconciledProduction(
  date: string,
  partyId: number | null,
  options?: { query?: Partial<UseQueryOptions<UnreconciledProductionResponse, ErrorType<unknown>>> },
) {
  return useQuery({
    queryKey: getUnreconciledProductionQueryKey(date, partyId) as unknown as QueryKey,
    queryFn: ({ signal }) =>
      customFetch<UnreconciledProductionResponse>(
        `/api/daily-production/unreconciled?date=${encodeURIComponent(date)}&partyId=${partyId}`,
        { method: "GET", signal },
      ),
    enabled: Boolean(date) && partyId != null,
    ...options?.query,
  });
}

// ─── Delete (hard) ────────────────────────────────────────────────────────
// Backs the grid's Delete action. Returns 204, so there is no response body
// to type — customFetch resolves to null for no-content responses.

export function useDeleteDailyProduction() {
  return useMutation<null, ErrorType<unknown>, { id: number }>({
    mutationFn: ({ id }) =>
      customFetch<null>(`/api/daily-production/${id}`, { method: "DELETE" }),
  });
}

// ─── Cancel / soft delete (superseded by the hard delete above) ───────────

export function useCancelDailyProduction() {
  return useMutation<DailyProductionDetailResponse, ErrorType<unknown>, { id: number; updatedBy: string }>({
    mutationFn: ({ id, updatedBy }) =>
      customFetch<DailyProductionDetailResponse>(`/api/daily-production/${id}/cancel`, {
        method: "POST",
        body: JSON.stringify({ updatedBy }),
      }),
  });
}
