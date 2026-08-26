import React, { useState, useEffect, useCallback } from 'react';
import { useAdmin } from '../hooks/useAdmin';
import { useAuth } from '../context/auth-context';

/**
 * TenantSwitcher Component
 * Dropdown for super-admins to switch between tenants.
 * Shown in the top-right nav. Only visible to the super-admin role.
 *
 * Issue #219 (Option B): switching the active tenant is client-held state —
 * it updates the auth context's activeTenantId, which the API client turns
 * into the X-Tenant-Id header on subsequent requests. No bearer token is
 * re-issued and the page is not reloaded (React Query caches are cleared by
 * the caller on switch).
 */

interface TenantSwitcherProps {
  isSuperAdmin?: boolean;
}

export const TenantSwitcher: React.FC<TenantSwitcherProps> = ({ isSuperAdmin = false }) => {
  const { activeTenantId, switchTenant } = useAuth();
  const { tenants, loading, getTenants } = useAdmin();
  const [isOpen, setIsOpen] = useState(false);

  // Only render for super-admins.
  if (!isSuperAdmin) {
    return null;
  }

  // Load the tenant list once on mount (super-admin platform view).
  useEffect(() => {
    let cancelled = false;
    getTenants().catch(() => { /* surface via loading state; non-fatal */ });
    return () => { cancelled = true; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const currentTenant = tenants.find((t) => t.id === activeTenantId) ?? null;

  const handleSwitch = useCallback(
    (tenantId: number) => {
      switchTenant(tenantId);
      setIsOpen(false);
      // Reload the app so every tenant-scoped screen, query cache and the
      // dashboards re-fetch for the newly selected tenant (issue #219 Q3d).
      // The active tenant is persisted by switchTenant and restored on boot.
      window.location.reload();
    },
    [switchTenant],
  );

  if (!isSuperAdmin || tenants.length === 0) {
    return null;
  }

  return (
    <div className="relative inline-block">
      {/* Dropdown Toggle Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition"
        title="Switch between managed tenants"
      >
        <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
          <path d="M10.5 1.5H2.5A1 1 0 001.5 2.5v15a1 1 0 001 1h15a1 1 0 001-1v-8M7 10a3 3 0 110-6 3 3 0 010 6zM1.5 19.1c0-1.1 1.3-2.1 3-2.1h5c1.7 0 3 1 3 2.1M11 4h6m0 3h-6" />
        </svg>
        <span className="hidden sm:inline">{currentTenant?.name ?? 'Select Tenant'}</span>
        <span className="sm:hidden">Tenant</span>
        <svg className={`w-4 h-4 transition-transform ${isOpen ? 'rotate-180' : ''}`} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
          <path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" />
        </svg>
      </button>

      {/* Dropdown Menu */}
      {isOpen && (
        <div className="absolute right-0 mt-2 w-64 bg-white rounded-lg shadow-lg border border-gray-200 z-50">
          <div className="px-4 py-3 border-b border-gray-200">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
              Tenants ({tenants.length})
            </p>
          </div>

          <div className="max-h-64 overflow-y-auto">
            {loading ? (
              <div className="px-4 py-3 text-sm text-gray-500">Loading...</div>
            ) : tenants.length === 0 ? (
              <div className="px-4 py-3 text-sm text-gray-500">No tenants found</div>
            ) : (
              tenants.map((tenant) => (
                <button
                  key={tenant.id}
                  onClick={() => handleSwitch(tenant.id)}
                  className={`w-full text-left px-4 py-3 text-sm hover:bg-gray-50 transition border-b border-gray-100 last:border-b-0 ${
                    activeTenantId === tenant.id ? 'bg-blue-50 border-l-4 border-l-blue-500' : ''
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">{tenant.name}</p>
                      <p className="text-xs text-gray-500">{tenant.slug}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <span
                        className={`inline-block w-2 h-2 rounded-full ${
                          tenant.status === 'active'
                            ? 'bg-green-500'
                            : tenant.status === 'suspended'
                            ? 'bg-yellow-500'
                            : 'bg-gray-400'
                        }`}
                        title={`Status: ${tenant.status}`}
                      />
                      {activeTenantId === tenant.id && (
                        <svg className="w-4 h-4 text-blue-500" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                          <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                      )}
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>

          <div className="px-4 py-3 border-t border-gray-200 bg-gray-50">
            <p className="text-xs text-gray-600">
              Click a tenant to switch • green=active, yellow=suspended
            </p>
          </div>
        </div>
      )}

      {/* Close dropdown when clicking outside */}
      {isOpen && (
        <div className="fixed inset-0 z-40" onClick={() => setIsOpen(false)} />
      )}
    </div>
  );
};

export default TenantSwitcher;
