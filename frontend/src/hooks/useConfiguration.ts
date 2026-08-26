import { useState, useEffect, useCallback, createElement, type ReactNode, type ComponentType } from 'react';
import { customFetch } from '@/vendor/api-client-react/custom-fetch';

/**
 * useConfiguration Hook
 * Manages tenant configuration, settings, and feature flags
 */

export interface TenantSettings {
  id: number;
  tenant_id: number;
  company_registration_number?: string;
  company_tax_id?: string;
  company_phone?: string;
  company_email?: string;
  company_address?: string;
  company_city?: string;
  company_country?: string;
  timezone: string;
  currency: string;
  language: string;
  tax_enabled: boolean;
  default_tax_rate: number;
  invoice_prefix: string;
  invoice_start_number: number;
  email_from_name?: string;
  email_from_address?: string;
}

export interface FeatureFlag {
  id: number;
  feature_key: string;
  feature_name: string;
  is_enabled: boolean;
  category: string;
  max_users?: number;
}

export interface IntegrationSetting {
  id: number;
  integration_key: string;
  integration_name: string;
  is_enabled: boolean;
  is_configured: boolean;
  last_sync_at?: string;
}

export interface ConfigurationSummary {
  company_name: string;
  timezone: string;
  currency: string;
  language: string;
  features_enabled_count: number;
  features_total_count: number;
  enabled_features: string[];
  integrations_configured: number;
  integrations_enabled: string[];
}

interface UseConfigurationReturn {
  settings: TenantSettings | null;
  features: FeatureFlag[];
  integrations: IntegrationSetting[];
  summary: ConfigurationSummary | null;
  loading: boolean;
  error: string | null;
  updateSettings: (settings: Partial<TenantSettings>) => Promise<void>;
  toggleFeature: (featureKey: string, isEnabled: boolean) => Promise<void>;
  updateIntegration: (integrationKey: string, config: any) => Promise<void>;
  refreshConfiguration: () => Promise<void>;
}

export const useConfiguration = (): UseConfigurationReturn => {
  const [settings, setSettings] = useState<TenantSettings | null>(null);
  const [features, setFeatures] = useState<FeatureFlag[]>([]);
  const [integrations, setIntegrations] = useState<IntegrationSetting[]>([]);
  const [summary, setSummary] = useState<ConfigurationSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch all configuration on mount
  useEffect(() => {
    fetchConfiguration();
  }, []);

  const fetchConfiguration = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      // Fetch in parallel (token + X-Tenant-Id attached by customFetch).
      const [settingsRes, featuresRes, integrationsRes, summaryRes] = await Promise.all([
        customFetch<TenantSettings>('/api/configuration/settings'),
        customFetch<{ features: FeatureFlag[] }>('/api/configuration/features'),
        customFetch<{ integrations: IntegrationSetting[] }>('/api/configuration/integrations').catch(() => ({ integrations: [] })),
        customFetch<ConfigurationSummary>('/api/configuration/summary'),
      ]);

      setSettings(settingsRes);
      setFeatures(featuresRes.features ?? []);
      setIntegrations(integrationsRes.integrations ?? []);
      setSummary(summaryRes);
    } catch (err) {
      console.error('Error fetching configuration:', err);
      setError('Failed to load configuration');
    } finally {
      setLoading(false);
    }
  }, []);

  const updateSettings = async (newSettings: Partial<TenantSettings>) => {
    try {
      setLoading(true);
      const response = await customFetch<{ data: TenantSettings }>('/api/configuration/settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newSettings),
      });
      setSettings(response.data);
    } catch (err) {
      console.error('Error updating settings:', err);
      setError('Failed to update settings');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const toggleFeature = async (featureKey: string, isEnabled: boolean) => {
    try {
      setLoading(true);
      const response = await customFetch<{ data: FeatureFlag }>(`/api/configuration/features/${featureKey}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ is_enabled: isEnabled }),
      });

      setFeatures((prev) =>
        prev.map((f) => (f.feature_key === featureKey ? response.data : f))
      );
    } catch (err) {
      console.error('Error toggling feature:', err);
      setError('Failed to update feature');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const updateIntegration = async (integrationKey: string, config: any) => {
    try {
      setLoading(true);
      const response = await customFetch<{ data: IntegrationSetting }>(`/api/configuration/integrations/${integrationKey}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config),
      });
      setIntegrations((prev) =>
        prev.map((i) => (i.integration_key === integrationKey ? response.data : i))
      );
    } catch (err) {
      console.error('Error updating integration:', err);
      setError('Failed to update integration');
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    settings,
    features,
    integrations,
    summary,
    loading,
    error,
    updateSettings,
    toggleFeature,
    updateIntegration,
    refreshConfiguration: fetchConfiguration,
  };
};

/**
 * Helper hook to check if a feature is enabled
 */
export const useFeatureFlag = (featureKey: string) => {
  const { features } = useConfiguration();
  const feature = features.find((f) => f.feature_key === featureKey);
  return feature?.is_enabled || false;
};

/**
 * Helper hook to get feature details
 */
export const useFeatureDetails = (featureKey: string) => {
  const { features } = useConfiguration();
  return features.find((f) => f.feature_key === featureKey) || null;
};

/**
 * Higher-order component to guard features
 */
export const withFeatureFlag =
  (featureKey: string, fallback?: ReactNode) =>
  (Component: ComponentType<any>) =>
  (props: any) => {
    const isEnabled = useFeatureFlag(featureKey);

    if (!isEnabled) {
      return fallback || null;
    }

    return createElement(Component, props);
  };
