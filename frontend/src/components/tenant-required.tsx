import { useAuth } from "@/context/auth-context";
import { Button } from "@/components/ui/button";
import { useLocation } from "wouter";

/**
 * TenantRequired — issue #219 Q3b.
 *
 * Blocks tenant-scoped screens for a super-admin who hasn't selected an active
 * tenant yet (activeTenantId === null) with a blocking overlay prompting them to
 * pick a tenant from the top-right switcher. Renders children normally once a
 * tenant is selected (or for tenant users who always have a home tenant).
 *
 * NOT used on super-admin platform routes (e.g. /admin/tenants) which must be
 * reachable before a tenant is chosen.
 */
export function TenantRequired({ children }: { children: React.ReactNode }) {
  const { isSuperAdmin, activeTenantId } = useAuth();
  const [, setLocation] = useLocation();

  if (!isSuperAdmin) {
    // Tenant users always have a home tenant; no gate.
    return <>{children}</>;
  }

  if (activeTenantId == null) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center gap-4 px-4 text-center">
        <div className="text-4xl">🏭</div>
        <h2 className="text-xl font-semibold text-gray-900">Select a tenant to continue</h2>
        <p className="max-w-md text-sm text-gray-500">
          You are signed in as a platform super-admin. Choose a tenant from the
          tenant switcher in the top-right corner to work with that tenant's data.
        </p>
        <Button onClick={() => setLocation("/admin/tenants")} variant="outline">
          Open Tenant Management
        </Button>
      </div>
    );
  }

  return <>{children}</>;
}
