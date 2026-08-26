import { useState, useCallback } from "react";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

export interface AuditLogRow {
  id: number;
  actorUserId: number | null;
  actorTenantId: number | null;
  targetTenantId: number | null;
  action: string;
  entityType: string | null;
  entityId: number | null;
  description: string | null;
  ipAddress: string | null;
  createdAt: string;
}

interface AuditLogsResult {
  total: number;
  page: number;
  perPage: number;
  totalPages: number;
  rows: AuditLogRow[];
}

export interface AuditLogsQuery {
  tenantId?: number;
  action?: string;
  from?: string;
  to?: string;
  page?: number;
  perPage?: number;
  search?: string;
}

interface UseAuditLogsReturn {
  result: AuditLogsResult | null;
  loading: boolean;
  error: string | null;
  query: (params: AuditLogsQuery) => Promise<void>;
}

export const useAuditLogs = (): UseAuditLogsReturn => {
  const [result, setResult] = useState<AuditLogsResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const query = useCallback(async (params: AuditLogsQuery) => {
    try {
      setLoading(true);
      setError(null);
      const qs = new URLSearchParams();
      if (params.tenantId) qs.set("tenantId", String(params.tenantId));
      if (params.action) qs.set("action", params.action);
      if (params.from) qs.set("from", params.from);
      if (params.to) qs.set("to", params.to);
      if (params.page) qs.set("page", String(params.page));
      if (params.perPage) qs.set("perPage", String(params.perPage));
      if (params.search) qs.set("search", params.search);
      const data = await customFetch<AuditLogsResult>(`/api/audit-logs?${qs.toString()}`, { method: "GET" });
      setResult(data);
    } catch (err) {
      setError("Failed to load audit logs");
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  return { result, loading, error, query };
};
