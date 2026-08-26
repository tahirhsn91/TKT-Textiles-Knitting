import { useState, useCallback } from "react";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

export interface TenantUsage {
  tenantId: number;
  name: string;
  slug: string;
  status: string;
  usage: {
    seats: { used: number; limit: number | null };
    transactions: { used: number; limit: number | null };
    records: { used: number; limit: number | null };
    auditEvents: number;
  };
}

interface UseTenantUsageReturn {
  usage: TenantUsage | null;
  loading: boolean;
  error: string | null;
  load: (tenantId: number) => Promise<void>;
}

/** Fetch the resource-usage snapshot for a tenant (super-admin panel). */
export const useTenantUsage = (): UseTenantUsageReturn => {
  const [usage, setUsage] = useState<TenantUsage | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async (tenantId: number) => {
    try {
      setLoading(true);
      setError(null);
      const data = await customFetch<TenantUsage>(`/api/admin/tenants/${tenantId}/usage`, { method: "GET" });
      setUsage(data);
    } catch (err) {
      setError("Failed to load tenant usage");
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  return { usage, loading, error, load };
};
