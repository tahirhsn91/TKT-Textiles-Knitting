import { useState } from "react";
import { customFetch } from "@/vendor/api-client-react/custom-fetch";

/**
 * useAdmin Hook
 * Super-admin operations: tenant management + tenant list for the switcher.
 * Uses customFetch so the bearer token (and active-tenant header) are attached.
 *
 * NOTE (issue #219 Option B): tenant switching is client-held state — the
 * active tenant is set via the auth context (switchTenant) and carried on the
 * X-Tenant-Id header. It does NOT re-issue a bearer token.
 */

export interface Tenant {
  id: number;
  name: string;
  slug: string;
  industry: string | null;
  status: "active" | "suspended" | "inactive";
  created_at?: string;
  user_count?: number;
}

export interface TenantDetails extends Tenant {
  settings?: any;
  branding?: any;
  admins?: any[];
}

interface UseAdminReturn {
  tenants: Tenant[];
  loading: boolean;
  error: string | null;
  getTenants: () => Promise<void>;
  getTenantDetails: (tenantId: number) => Promise<TenantDetails>;
  createTenant: (data: {
    name: string;
    slug: string;
    industry: string;
    timezone: string;
    currency: string;
    language: string;
  }) => Promise<Tenant>;
  updateTenant: (tenantId: number, data: any) => Promise<Tenant>;
  updateTenantStatus: (tenantId: number, status: string) => Promise<Tenant>;
  getTenantStats: (tenantId: number) => Promise<any>;
}

export const useAdmin = (): UseAdminReturn => {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // List ALL tenants (super-admin platform view). Uses the app http client so
  // the bearer token is attached.
  const getTenants = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await customFetch<{ tenants: Tenant[] }>("/api/admin/tenants", { method: "GET" });
      setTenants(data.tenants ?? []);
    } catch (err) {
      console.error("Error fetching tenants:", err);
      setError("Failed to fetch tenants");
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getTenantDetails = async (tenantId: number): Promise<TenantDetails> => {
    try {
      return await customFetch<TenantDetails>(`/api/admin/tenants/${tenantId}`, { method: "GET" });
    } catch (err) {
      console.error("Error fetching tenant details:", err);
      setError("Failed to fetch tenant details");
      throw err;
    }
  };

  const createTenant = async (data: {
    name: string;
    slug: string;
    industry: string;
    timezone: string;
    currency: string;
    language: string;
  }): Promise<Tenant> => {
    try {
      const { data: created } = await customFetch<{ data: Tenant }>("/api/admin/tenants", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      setTenants((prev) => [...prev, created]);
      return created;
    } catch (err) {
      console.error("Error creating tenant:", err);
      setError("Failed to create tenant");
      throw err;
    }
  };

  const updateTenant = async (tenantId: number, data: any): Promise<Tenant> => {
    try {
      const { data: updated } = await customFetch<{ data: Tenant }>(`/api/admin/tenants/${tenantId}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });
      setTenants((prev) => prev.map((t) => (t.id === tenantId ? updated : t)));
      return updated;
    } catch (err) {
      console.error("Error updating tenant:", err);
      setError("Failed to update tenant");
      throw err;
    }
  };

  const updateTenantStatus = async (tenantId: number, status: string): Promise<Tenant> => {
    try {
      const { data: updated } = await customFetch<{ data: Tenant }>(`/api/admin/tenants/${tenantId}/status`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status }),
      });
      setTenants((prev) => prev.map((t) => (t.id === tenantId ? updated : t)));
      return updated;
    } catch (err) {
      console.error("Error updating tenant status:", err);
      setError("Failed to update tenant status");
      throw err;
    }
  };

  const getTenantStats = async (tenantId: number): Promise<any> => {
    try {
      return await customFetch(`/api/admin/tenants/${tenantId}/stats`, { method: "GET" });
    } catch (err) {
      console.error("Error fetching tenant stats:", err);
      throw err;
    }
  };

  return {
    tenants,
    loading,
    error,
    getTenants,
    getTenantDetails,
    createTenant,
    updateTenant,
    updateTenantStatus,
    getTenantStats,
  };
};
