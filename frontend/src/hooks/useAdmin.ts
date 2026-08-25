import { useState, useEffect } from 'react';
import axios from 'axios';

/**
 * useAdmin Hook
 * Manages super-admin operations: tenant management, creation, switching
 */

export interface Tenant {
  id: number;
  name: string;
  slug: string;
  industry: string;
  status: 'active' | 'suspended' | 'inactive';
  created_at: string;
  user_count?: number;
}

export interface TenantDetails extends Tenant {
  settings?: any;
  branding?: any;
  admins?: any[];
}

interface UseAdminReturn {
  tenants: Tenant[];
  currentTenantId: number | null;
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
  switchTenant: (tenantId: number) => Promise<{ new_token: string; tenant_name: string }>;
  getTenantStats: (tenantId: number) => Promise<any>;
  getMyTenants: () => Promise<void>;
}

export const useAdmin = (): UseAdminReturn => {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [currentTenantId, setCurrentTenantId] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Get all tenants (admin view)
  const getTenants = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await axios.get('/api/v1/admin/tenants');
      setTenants(response.data.tenants);
    } catch (err) {
      console.error('Error fetching tenants:', err);
      setError('Failed to fetch tenants');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // Get tenant details
  const getTenantDetails = async (tenantId: number): Promise<TenantDetails> => {
    try {
      setLoading(true);
      const response = await axios.get(`/api/v1/admin/tenants/${tenantId}`);
      return response.data;
    } catch (err) {
      console.error('Error fetching tenant details:', err);
      setError('Failed to fetch tenant details');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // Create new tenant
  const createTenant = async (data: {
    name: string;
    slug: string;
    industry: string;
    timezone: string;
    currency: string;
    language: string;
  }): Promise<Tenant> => {
    try {
      setLoading(true);
      const response = await axios.post('/api/v1/admin/tenants', data);
      const newTenant = response.data.data;
      setTenants([...tenants, newTenant]);
      return newTenant;
    } catch (err) {
      console.error('Error creating tenant:', err);
      setError('Failed to create tenant');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // Update tenant
  const updateTenant = async (tenantId: number, data: any): Promise<Tenant> => {
    try {
      setLoading(true);
      const response = await axios.put(`/api/v1/admin/tenants/${tenantId}`, data);
      const updated = response.data.data;
      setTenants(tenants.map((t) => (t.id === tenantId ? updated : t)));
      return updated;
    } catch (err) {
      console.error('Error updating tenant:', err);
      setError('Failed to update tenant');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // Update tenant status
  const updateTenantStatus = async (tenantId: number, status: string): Promise<Tenant> => {
    try {
      setLoading(true);
      const response = await axios.put(`/api/v1/admin/tenants/${tenantId}/status`, { status });
      const updated = response.data.data;
      setTenants(tenants.map((t) => (t.id === tenantId ? updated : t)));
      return updated;
    } catch (err) {
      console.error('Error updating tenant status:', err);
      setError('Failed to update tenant status');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // Switch tenant (get new token)
  const switchTenant = async (tenantId: number): Promise<{ new_token: string; tenant_name: string }> => {
    try {
      setLoading(true);
      const response = await axios.post(`/api/v1/admin/switch-tenant/${tenantId}`);
      setCurrentTenantId(tenantId);
      return {
        new_token: response.data.new_token,
        tenant_name: response.data.tenant_name,
      };
    } catch (err) {
      console.error('Error switching tenant:', err);
      setError('Failed to switch tenant');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // Get tenant stats
  const getTenantStats = async (tenantId: number): Promise<any> => {
    try {
      const response = await axios.get(`/api/v1/admin/tenants/${tenantId}/stats`);
      return response.data;
    } catch (err) {
      console.error('Error fetching tenant stats:', err);
      throw err;
    }
  };

  // Get my tenants (admin's managed tenants)
  const getMyTenants = async () => {
    try {
      setLoading(true);
      const response = await axios.get('/api/v1/admin/my-tenants');
      setTenants(response.data.tenants);
    } catch (err) {
      console.error('Error fetching my tenants:', err);
      setError('Failed to fetch tenants');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    tenants,
    currentTenantId,
    loading,
    error,
    getTenants,
    getTenantDetails,
    createTenant,
    updateTenant,
    updateTenantStatus,
    switchTenant,
    getTenantStats,
    getMyTenants,
  };
};
