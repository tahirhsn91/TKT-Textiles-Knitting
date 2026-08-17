/**
 * Hand-written query/mutation hooks for the Factory Maintenance resource
 * (issue #109). Mirrors use-daily-deliveries.ts conventions.
 */
import {
  useQuery,
  useMutation,
  type UseQueryOptions,
  type QueryKey,
} from "@tanstack/react-query";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";
import type { ErrorType } from "@/vendor/api-client-react/custom-fetch";

/** One factory_maintenance row. */
export interface FactoryMaintenanceRow {
  id: number;
  maintenanceDate: string;
  category: string;
  maintenanceWork: string;
  status: "submitted" | "cancelled";
  createdBy: string;
}

export interface FactoryMaintenanceListResponse {
  maintenanceDate: string;
  page: number;
  pageSize: number;
  total: number;
  rows: FactoryMaintenanceRow[];
  /** Per-day job count from the 1st of the month through the selected date. */
  monthSeries: { date: string; jobs: number }[];
}

export interface FactoryMaintenanceDetail extends FactoryMaintenanceRow {
  updatedBy: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface FactoryMaintenancePayload {
  maintenanceDate: string;
  category: string;
  maintenanceWork: string;
  createdBy: string;
  updatedBy?: string;
}

// ─── List by date + status (paginated) ─────────────────────────────────────

export const getFactoryMaintenanceListQueryKey = (
  date: string,
  status: "submitted" | "cancelled",
  page: number,
) => [`/api/maintenance/factory`, { date, status, page }] as const;

export function useGetFactoryMaintenanceList(
  date: string,
  status: "submitted" | "cancelled",
  page: number,
  options?: { query?: Partial<UseQueryOptions<FactoryMaintenanceListResponse, ErrorType<unknown>>> },
) {
  return useQuery<FactoryMaintenanceListResponse, ErrorType<unknown>>({
    queryKey: getFactoryMaintenanceListQueryKey(date, status, page) as QueryKey,
    queryFn: ({ signal }) =>
      customFetch<FactoryMaintenanceListResponse>(
        `/api/maintenance/factory?date=${encodeURIComponent(date)}&status=${status}&page=${page}&pageSize=50`,
        { signal },
      ),
    ...options?.query,
  });
}

// ─── Get one (detail) ──────────────────────────────────────────────────────

export function useGetFactoryMaintenance(
  id: number | null,
  options?: { query?: Partial<UseQueryOptions<FactoryMaintenanceDetail, ErrorType<unknown>>> },
) {
  return useQuery<FactoryMaintenanceDetail, ErrorType<unknown>>({
    queryKey: [`/api/maintenance/factory/${id}`] as QueryKey,
    queryFn: ({ signal }) => customFetch<FactoryMaintenanceDetail>(`/api/maintenance/factory/${id}`, { signal }),
    enabled: id != null,
    ...options?.query,
  });
}

// ─── Create / Update / Soft-delete / Restore ───────────────────────────────

export function useCreateFactoryMaintenance() {
  return useMutation({
    mutationFn: ({ data }: { data: FactoryMaintenancePayload }) =>
      customFetch<{ id: number }>("/api/maintenance/factory", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      }),
  });
}

export function useUpdateFactoryMaintenance() {
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: FactoryMaintenancePayload }) =>
      customFetch<{ id: number }>(`/api/maintenance/factory/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      }),
  });
}

/** Soft-delete (status -> cancelled) or restore (-> submitted). */
export function useSetFactoryMaintenanceStatus() {
  return useMutation({
    mutationFn: ({ id, status, updatedBy }: { id: number; status: "submitted" | "cancelled"; updatedBy?: string | null }) =>
      customFetch<{ id: number; status: "submitted" | "cancelled" }>(`/api/maintenance/factory/${id}/status`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status, updatedBy }),
      }),
  });
}
