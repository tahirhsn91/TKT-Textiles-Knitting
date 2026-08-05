/**
 * Hand-written query/mutation hooks for the Yarn Receipt resource.
 *
 * Same hand-written shape as `use-daily-production.ts` (the API codegen
 * hasn't been re-run against /api/yarn-receipts yet).
 */
import {
  useQuery,
  useMutation,
  type UseQueryOptions,
  type QueryKey,
} from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import type { ErrorType } from "@/vendor/api-client-react/custom-fetch";

/** One yarn_receipt_header summary row — one line per receipt in the list. */
export interface YarnReceiptSummaryRow {
  id: number;
  docNumber: string;
  receiptDate: string;
  partyId: number;
  partyName: string | null;
  createdBy: string;
  /** True when booked into a Yarn Receipt transaction — read-only afterwards. */
  reconciled: boolean;
  reconciledTransactionId: number | null;
  lineCount: number;
  totalQty: number;
  totalNetWeight: string;
}

export interface YarnReceiptSummaryResponse {
  receiptDate: string;
  rows: YarnReceiptSummaryRow[];
  monthToDate: {
    totalQty: number;
    totalNetWeight: string;
  };
}

export interface YarnReceiptLine {
  id: number;
  yarnCountId: number;
  yarnCountName: string | null;
  yarnBrandId: number;
  yarnBrandName: string | null;
  quantity: number;
  netWeight: string;
}

export interface YarnReceiptDetail {
  id: number;
  docNumber: string;
  receiptDate: string;
  partyId: number;
  partyName: string | null;
  createdBy: string;
  updatedBy: string | null;
  createdAt: string;
  updatedAt: string;
  lines: YarnReceiptLine[];
}

export interface YarnReceiptPayload {
  docNumber: string;
  receiptDate: string;
  partyId: number;
  createdBy: string;
  updatedBy?: string;
  lines: { yarnCountId: number; yarnBrandId: number; quantity: number; netWeight: string }[];
}

// ─── Get receipt summary by date ───────────────────────────────────────────

export const getYarnReceiptsSummaryQueryKey = (date: string) =>
  [`/api/yarn-receipts`, { date }] as const;

export function useGetYarnReceiptsSummary(
  date: string,
  options?: { query?: Partial<UseQueryOptions<YarnReceiptSummaryResponse, ErrorType<unknown>>> },
) {
  return useQuery<YarnReceiptSummaryResponse, ErrorType<unknown>>({
    queryKey: getYarnReceiptsSummaryQueryKey(date) as QueryKey,
    queryFn: () =>
      customFetch<YarnReceiptSummaryResponse>(
        `/api/yarn-receipts?date=${encodeURIComponent(date)}`,
      ),
    ...options?.query,
  });
}

// ─── Analytics (day lines + month series) ──────────────────────────────────

export interface YarnReceiptAnalyticsLine {
  lineId: number;
  receiptId: number;
  partyName: string | null;
  yarnCountId: number;
  yarnCountName: string | null;
  yarnBrandId: number;
  yarnBrandName: string | null;
  quantity: number;
  netWeight: string;
}

export interface YarnReceiptMonthPoint {
  date: string;
  totalQty: number;
  totalNetWeight: string;
}

export interface YarnReceiptAnalyticsResponse {
  receiptDate: string;
  lines: YarnReceiptAnalyticsLine[];
  monthSeries: YarnReceiptMonthPoint[];
}

export function useYarnReceiptsAnalytics(
  date: string,
  options?: { query?: Partial<UseQueryOptions<YarnReceiptAnalyticsResponse, ErrorType<unknown>>> },
) {
  return useQuery<YarnReceiptAnalyticsResponse, ErrorType<unknown>>({
    queryKey: [`/api/yarn-receipts/analytics`, { date }] as QueryKey,
    queryFn: () =>
      customFetch<YarnReceiptAnalyticsResponse>(
        `/api/yarn-receipts/analytics?date=${encodeURIComponent(date)}`,
      ),
    ...options?.query,
  });
}

// ─── Unreconciled receipts for a date + party (New Transaction screen) ─────

export interface UnreconciledYarnReceiptRow {
  id: number;
  receiptDate: string;
  partyId: number;
  partyName: string | null;
  lineId: number;
  yarnCountId: number;
  yarnCountName: string | null;
  yarnBrandId: number;
  yarnBrandName: string | null;
  quantity: number;
  netWeight: string;
}

export interface UnreconciledYarnReceiptResponse {
  receiptDate: string;
  partyId: number;
  rows: UnreconciledYarnReceiptRow[];
  /** Distinct receipt header ids to claim on save. */
  receiptIds: number[];
}

export function useUnreconciledYarnReceipts(
  date: string,
  partyId: number | null | undefined,
) {
  return useQuery<UnreconciledYarnReceiptResponse, ErrorType<unknown>>({
    queryKey: [`/api/yarn-receipts/unreconciled`, { date, partyId }] as QueryKey,
    queryFn: () =>
      customFetch<UnreconciledYarnReceiptResponse>(
        `/api/yarn-receipts/unreconciled?date=${encodeURIComponent(date)}&partyId=${partyId}`,
      ),
    enabled: Boolean(date && partyId),
  });
}

// ─── Get one receipt (detail) ──────────────────────────────────────────────

export function useGetYarnReceipt(
  id: number | null,
  options?: { query?: Partial<UseQueryOptions<YarnReceiptDetail, ErrorType<unknown>>> },
) {
  return useQuery<YarnReceiptDetail, ErrorType<unknown>>({
    queryKey: [`/api/yarn-receipts/${id}`] as QueryKey,
    queryFn: () => customFetch<YarnReceiptDetail>(`/api/yarn-receipts/${id}`),
    enabled: id != null,
    ...options?.query,
  });
}

// ─── Create ────────────────────────────────────────────────────────────────

export function useCreateYarnReceipt() {
  return useMutation({
    mutationFn: ({ data }: { data: YarnReceiptPayload }) =>
      customFetch<{ id: number }>("/api/yarn-receipts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      }),
  });
}

// ─── Update ────────────────────────────────────────────────────────────────

export function useUpdateYarnReceipt() {
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: YarnReceiptPayload }) =>
      customFetch<{ id: number }>(`/api/yarn-receipts/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      }),
  });
}

// ─── Delete ────────────────────────────────────────────────────────────────

export function useDeleteYarnReceipt() {
  return useMutation({
    mutationFn: ({ id }: { id: number }) =>
      customFetch<{ id: number }>(`/api/yarn-receipts/${id}`, { method: "DELETE" }),
  });
}
