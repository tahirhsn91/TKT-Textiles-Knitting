/**
 * Hand-written query/mutation hooks for the Machine Maintenance resource
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

/** One machine_maintenance row. */
export interface MachineMaintenanceRow {
  id: number;
  maintenanceDate: string;
  machineId: number;
  machineNumber: string | null;
  machineName: string | null;
  maintenanceWork: string;
  cost: string | null;
  vendor: string | null;
  status: "submitted" | "cancelled";
  createdBy: string;
}

export interface MachineMaintenanceListResponse {
  maintenanceDate: string;
  page: number;
  pageSize: number;
  total: number;
  rows: MachineMaintenanceRow[];
  /** Day total cost (submitted records) for the selected date. */
  dayTotalCost: string;
  /** Month-to-date cost (submitted records) through the selected date. */
  monthToDateCost: string;
  /** Per-day cost + job count from the 1st of the month through the selected date. */
  monthSeries: { date: string; jobs: number; cost: string }[];
}

export interface MachineMaintenanceDetail extends MachineMaintenanceRow {
  updatedBy: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface MachineMaintenancePayload {
  maintenanceDate: string;
  machineId: number;
  maintenanceWork: string;
  cost?: number | null;
  vendor?: string | null;
  createdBy: string;
  updatedBy?: string;
}

// ─── List by date + status (paginated) ─────────────────────────────────────

export const getMachineMaintenanceListQueryKey = (
  date: string,
  status: "submitted" | "cancelled",
  page: number,
) => [`/api/maintenance/machine`, { date, status, page }] as const;

export function useGetMachineMaintenanceList(
  date: string,
  status: "submitted" | "cancelled",
  page: number,
  options?: { query?: Partial<UseQueryOptions<MachineMaintenanceListResponse, ErrorType<unknown>>> },
) {
  return useQuery<MachineMaintenanceListResponse, ErrorType<unknown>>({
    queryKey: getMachineMaintenanceListQueryKey(date, status, page) as QueryKey,
    queryFn: () =>
      customFetch<MachineMaintenanceListResponse>(
        `/api/maintenance/machine?date=${encodeURIComponent(date)}&status=${status}&page=${page}&pageSize=50`,
      ),
    ...options?.query,
  });
}

// ─── Get one (detail) ──────────────────────────────────────────────────────

export function useGetMachineMaintenance(
  id: number | null,
  options?: { query?: Partial<UseQueryOptions<MachineMaintenanceDetail, ErrorType<unknown>>> },
) {
  return useQuery<MachineMaintenanceDetail, ErrorType<unknown>>({
    queryKey: [`/api/maintenance/machine/${id}`] as QueryKey,
    queryFn: () => customFetch<MachineMaintenanceDetail>(`/api/maintenance/machine/${id}`),
    enabled: id != null,
    ...options?.query,
  });
}

// ─── Create / Update / Soft-delete / Restore ───────────────────────────────

export function useCreateMachineMaintenance() {
  return useMutation({
    mutationFn: ({ data }: { data: MachineMaintenancePayload }) =>
      customFetch<{ id: number }>("/api/maintenance/machine", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      }),
  });
}

export function useUpdateMachineMaintenance() {
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: MachineMaintenancePayload }) =>
      customFetch<{ id: number }>(`/api/maintenance/machine/${id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      }),
  });
}

/** Soft-delete (status -> cancelled) or restore (-> submitted). */
export function useSetMachineMaintenanceStatus() {
  return useMutation({
    mutationFn: ({ id, status, updatedBy }: { id: number; status: "submitted" | "cancelled"; updatedBy?: string | null }) =>
      customFetch<{ id: number; status: "submitted" | "cancelled" }>(`/api/maintenance/machine/${id}/status`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status, updatedBy }),
      }),
  });
}
