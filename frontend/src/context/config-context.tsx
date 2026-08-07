import { createContext, useContext, type ReactNode } from "react";
import { useListConfigurationCrud } from "@/vendor/api-client-react";

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
};

const ConfigContext = createContext<ConfigContextValue | null>(null);

/** System configuration code for the Reconciliation lock. */
export const RECONCILED_LOCK_CODE = "0001";

export function ConfigurationProvider({ children }: { children: ReactNode }) {
  const { data: configurations, isLoading } = useListConfigurationCrud();

  const reconciledLockEnabled =
    configurations?.find((c) => c.code === RECONCILED_LOCK_CODE)?.enabled ?? false;

  return (
    <ConfigContext.Provider
      value={{ configurations, isLoading, reconciledLockEnabled }}
    >
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
