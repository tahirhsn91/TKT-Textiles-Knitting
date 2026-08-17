/**
 * Hand-written query/mutation hooks for the Daily Delivery resource.
 * Same shape as use-yarn-receipts.ts / use-daily-production.ts.
 */
import {
  useQuery,
  useMutation,
  type UseQueryOptions,
  type QueryKey,
} from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import type { ErrorType } from "@/vendor/api-client-react/custom-fetch";

/** One daily_delivery row — the list renders one line per delivery. */
export interface DailyDeliveryRow {
  id: number;
  deliveryDate: string;
  partyId: number;
  partyName: string | null;
  yarnTypeId: number;
  yarnTypeName: string | null;
  challanNo: string;
  sl: string | null;
  gsm: number | null;
  quantity: number;
  netWeight: string;
  createdBy: string;
  reconciled: boolean;
  reconciledTransactionId: number | null;
}

export interface DailyDeliverySummaryResponse {
  deliveryDate: string;
  rows: DailyDeliveryRow[];
  monthToDate: {
    totalQty: number;
    totalNetWeight: string;
  };
  /** Per-day totals from the 1st of the month through the selected date. */
  monthSeries: { date: string; totalQty: number; totalNetWeight: string }[];
}

export interface DailyDeliveryDetail {
  id: number;
  deliveryDate: string;
  partyId: number;
  partyName: string | null;
  yarnTypeId: number;
  yarnTypeName: string | null;
  challanNo: string;
  sl: string | null;
  gsm: number | null;
  quantity: number;
  netWeight: string;
  createdBy: string;
  updatedBy: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface DailyDeliveryPayload {
  deliveryDate: string;
  partyId: number;
  yarnTypeId: number;
  challanNo: string;
  sl?: string | null;
  gsm?: number | null;
  quantity: number;
  netWeight: string;
  createdBy: string;
  updatedBy?: string;
}

// ─── Get delivery summary by date ───────────────────────────────────────────

export const getDailyDeliveriesSummaryQueryKey = (date: string) =>
  [`/api/daily-deliveries`, { date }] as const;

export function useGetDailyDeliveriesSummary(
  date: string,
  options?: { query?: Partial<UseQueryOptions<DailyDeliverySummaryResponse, ErrorType<unknown>>> },
) {
  return useQuery<DailyDeliverySummaryResponse, ErrorType<unknown>>({
    queryKey: getDailyDeliveriesSummaryQueryKey(date) as QueryKey,
    queryFn: ({ signal }) =>
      customFetch<DailyDeliverySummaryResponse>(
        `/api/daily-deliveries?date=${encodeURIComponent(date)}`,
        { signal },
      ),
    ...options?.query,
  });
}

// ─── Unreconciled deliveries for a date + party (New Transaction screen) ───

export interface UnreconciledDeliveryRow {
  id: number;
  deliveryDate: string;
  partyId: number;
  partyName: string | null;
  yarnTypeId: number;
  yarnTypeName: string | null;
  challanNo: string;
  sl: string | null;
  gsm: number | null;
  quantity: number;
  netWeight: string;
}

export function useUnreconciledDailyDeliveries(
  date: string,
  partyId: number | null | undefined,
) {
  return useQuery<{ deliveryDate: string; partyId: number; rows: UnreconciledDeliveryRow[] }, ErrorType<unknown>>({
    queryKey: [`/api/daily-deliveries/unreconciled`, { date, partyId }] as QueryKey,
    queryFn: ({ signal }) =>
      customFetch<{ deliveryDate: string; partyId: number; rows: UnreconciledDeliveryRow[] }>(
        `/api/daily-deliveries/unreconciled?date=${encodeURIComponent(date)}&partyId=${partyId}`,
        { signal },
      ),
    enabled: Boolean(date && partyId),
  });
}

// ─── Get one delivery (detail) ──────────────────────────────────────────────

export function useGetDailyDelivery(
  id: number | null,
  options?: { query?: Partial<UseQueryOptions<DailyDeliveryDetail, ErrorType<unknown>>> },
) {
  return useQuery<DailyDeliveryDetail, ErrorType<unknown>>({
    queryKey: [`/api/daily-deliveries/${id}`] as QueryKey,
    queryFn: ({ signal }) => customFetch<DailyDeliveryDetail>(`/api/daily-deliveries/${id}`, { signal }),
    enabled: id != null,
    ...options?.query,
  });
}

// ─── Create / Update / Delete ───────────────────────────────────────────────

export function useCreateDailyDelivery() {
  return useMutation({
    mutationFn: ({ data }: { data: DailyDeliveryPayload }) =>
      customFetch<{ id: number }>("/api/daily-deliveries", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      }),
  });
}

export function useUpdateDailyDelivery() {
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: DailyDeliveryPayload }) =>
      customFetch<{ id: number }>(`/api/daily-deliveries/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      }),
  });
}

export function useDeleteDailyDelivery() {
  return useMutation({
    mutationFn: ({ id }: { id: number }) =>
      customFetch<{ id: number }>(`/api/daily-deliveries/${id}`, { method: "DELETE" }),
  });
}
