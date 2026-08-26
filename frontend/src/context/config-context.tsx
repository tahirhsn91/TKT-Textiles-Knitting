import { createContext, useContext, type ReactNode } from "react";
import { useListConfigurationCrud } from "@/vendor/api-client-react";
import { useAuth } from "@/context/auth-context";

/**
 * Application-wide system configuration, loaded once on mount and cached by
 * React Query so every page shares the same view without refetching.
 *
 * Configuration records are read-only (managed via DB migration); this context
 * exposes their current values to feature logic — e.g. whether reconciled
 * daily-operation records should be locked.
 */
type ConfigContextValue = {
  /** Configurations loaded from GET /masters/configuration (may be undefined while loading). */
  configurations?: Array<{ id: number; name: string; code: string; description?: string | null; enabled: boolean }>;
  /** Whether loading is in progress. */
  isLoading: boolean;
  /** The `enabled` value of the configuration whose code is "0001" (Reconciled lock). */
  reconciledLockEnabled: boolean;
  /** The `enabled` value of the configuration whose code is "0002" (FBR DI Sandbox). */
  fbrSandboxEnabled: boolean;
};

const ConfigContext = createContext<ConfigContextValue | null>(null);

/** System configuration code for the Reconciliation lock. */
export const RECONCILED_LOCK_CODE = "0001";
/** System configuration code for the FBR DI sandbox toggle. */
export const FBR_DI_SANDBOX_CODE = "0002";

export function ConfigurationProvider({ children }: { children: ReactNode }) {
  // Configuration is tenant-scoped (issue #219) and only meaningful once the
  // user is authenticated. Don't fetch it on the login page / when signed out
  // — the endpoint requires auth + a tenant context, so firing it there just
  // produces an unnecessary (401) /api/masters/configuration call.
  const { isAuthenticated } = useAuth();
  const { data: configurations, isLoading } = useListConfigurationCrud({
    query: { enabled: isAuthenticated },
  });

  const reconciledLockEnabled =
    configurations?.find((c) => c.code === RECONCILED_LOCK_CODE)?.enabled ?? false;

  const newValue: ConfigContextValue = {
    configurations,
    isLoading,
    reconciledLockEnabled,
    fbrSandboxEnabled:
      configurations?.find((c) => c.code === FBR_DI_SANDBOX_CODE)?.enabled ?? true,
  };

  return (
    <ConfigContext.Provider value={newValue}>
      {children}
    </ConfigContext.Provider>
  );
}

/** Access the global configuration context. Throws outside the provider. */
export function useConfigurations(): ConfigContextValue {
  const ctx = useContext(ConfigContext);
  if (!ctx) {
    throw new Error("useConfigurations must be used within a ConfigurationProvider");
  }
  return ctx;
}

/**
 * Whether reconciled records should be locked. When the "Reconciled lock"
 * configuration (code 0001) is enabled, reconciled daily-operation records are
 * locked; when it's disabled, they stay editable.
 */
export function useReconciledLock(): boolean {
  return useConfigurations().reconciledLockEnabled;
}

/**
 * Whether FBR DI invoices should post to the sandbox environment. When the
 * "FBR DI Sandbox" configuration (code 0002) is enabled invoices post to the
 * sandbox; when disabled they post to production. Defaults to true (sandbox).
 */
export function useFbrSandboxEnabled(): boolean {
  return useConfigurations().fbrSandboxEnabled;
}
