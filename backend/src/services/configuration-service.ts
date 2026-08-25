import { db } from '../db/index.js';

/**
 * Configuration Service
 * Handles tenant settings, feature flags, and configuration management
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
  business_type?: string;
  industry_category?: string;
  timezone: string;
  currency: string;
  language: string;
  tax_enabled: boolean;
  default_tax_rate: number;
  invoice_prefix: string;
  invoice_start_number: number;
  email_from_name?: string;
  email_from_address?: string;
  send_invoice_notifications: boolean;
  send_order_notifications: boolean;
  status: string;
  created_at: Date;
  updated_at: Date;
}

export interface FeatureFlag {
  id: number;
  tenant_id: number;
  feature_key: string;
  feature_name: string;
  description?: string;
  is_enabled: boolean;
  is_beta: boolean;
  category: string;
  max_users?: number;
  max_orders?: number;
  enabled_at?: Date;
}

export interface ConfigurationAudit {
  id: number;
  tenant_id: number;
  changed_by?: number;
  change_type: string;
  entity_type: string;
  entity_key: string;
  old_value?: string;
  new_value?: string;
  change_reason?: string;
  ip_address?: string;
  created_at: Date;
}

export interface IntegrationSetting {
  id: number;
  tenant_id: number;
  integration_key: string;
  integration_name: string;
  is_enabled: boolean;
  is_configured: boolean;
  config_json?: any;
  last_sync_at?: Date;
  last_error_message?: string;
}

class ConfigurationService {
  /**
   * Get tenant settings
   */
  async getTenantSettings(tenantId: number): Promise<TenantSettings | null> {
    return db('tenant_settings').where({ tenant_id: tenantId }).first();
  }

  /**
   * Update tenant settings
   */
  async updateTenantSettings(
    tenantId: number,
    settings: Partial<TenantSettings>
  ): Promise<TenantSettings> {
    // Record audit trail
    const oldSettings = await this.getTenantSettings(tenantId);

    // Update settings
    const [updated] = await db('tenant_settings')
      .where({ tenant_id: tenantId })
      .update({
        ...settings,
        updated_at: new Date(),
      })
      .returning('*');

    // Log changes to audit trail
    for (const [key, newValue] of Object.entries(settings)) {
      const oldValue = (oldSettings as any)?.[key];
      if (oldValue !== newValue) {
        await this.logConfigurationChange(tenantId, {
          change_type: 'update',
          entity_type: 'tenant_settings',
          entity_key: key,
          old_value: String(oldValue || ''),
          new_value: String(newValue || ''),
        });
      }
    }

    return updated;
  }

  /**
   * Get all feature flags for a tenant
   */
  async getFeatureFlags(tenantId: number): Promise<FeatureFlag[]> {
    return db('feature_flags')
      .where({ tenant_id: tenantId })
      .orderBy('category', 'asc')
      .orderBy('feature_name', 'asc');
  }

  /**
   * Check if feature is enabled for tenant
   */
  async isFeatureEnabled(tenantId: number, featureKey: string): Promise<boolean> {
    const flag = await db('feature_flags')
      .where({ tenant_id: tenantId, feature_key: featureKey })
      .first();

    return flag?.is_enabled || false;
  }

  /**
   * Get feature flag details
   */
  async getFeatureFlag(tenantId: number, featureKey: string): Promise<FeatureFlag | null> {
    return db('feature_flags')
      .where({ tenant_id: tenantId, feature_key: featureKey })
      .first();
  }

  /**
   * Enable/disable feature for tenant
   */
  async updateFeatureFlag(
    tenantId: number,
    featureKey: string,
    isEnabled: boolean,
    changeReason?: string
  ): Promise<FeatureFlag> {
    const [updated] = await db('feature_flags')
      .where({ tenant_id: tenantId, feature_key: featureKey })
      .update({
        is_enabled: isEnabled,
        updated_at: new Date(),
        enabled_at: isEnabled ? new Date() : null,
      })
      .returning('*');

    // Log to audit trail
    await this.logConfigurationChange(tenantId, {
      change_type: 'update',
      entity_type: 'feature_flag',
      entity_key: featureKey,
      old_value: String(!isEnabled),
      new_value: String(isEnabled),
      change_reason: changeReason,
    });

    return updated;
  }

  /**
   * Get all integration settings for tenant
   */
  async getIntegrationSettings(tenantId: number): Promise<IntegrationSetting[]> {
    return db('integration_settings')
      .where({ tenant_id: tenantId })
      .select('id', 'tenant_id', 'integration_key', 'integration_name', 'is_enabled', 'is_configured', 'last_sync_at');
  }

  /**
   * Get specific integration settings
   */
  async getIntegrationSetting(
    tenantId: number,
    integrationKey: string
  ): Promise<IntegrationSetting | null> {
    return db('integration_settings')
      .where({ tenant_id: tenantId, integration_key: integrationKey })
      .first();
  }

  /**
   * Update integration settings
   */
  async updateIntegrationSetting(
    tenantId: number,
    integrationKey: string,
    settings: Partial<IntegrationSetting>
  ): Promise<IntegrationSetting> {
    const [updated] = await db('integration_settings')
      .where({ tenant_id: tenantId, integration_key: integrationKey })
      .update({
        ...settings,
        updated_at: new Date(),
      })
      .returning('*');

    // Log to audit trail
    await this.logConfigurationChange(tenantId, {
      change_type: 'update',
      entity_type: 'integration',
      entity_key: integrationKey,
      new_value: `${settings.is_enabled ? 'enabled' : 'disabled'}`,
    });

    return updated;
  }

  /**
   * Log configuration change to audit trail
   */
  async logConfigurationChange(
    tenantId: number,
    change: {
      change_type: string;
      entity_type: string;
      entity_key: string;
      old_value?: string;
      new_value?: string;
      change_reason?: string;
      changed_by?: number;
      ip_address?: string;
    }
  ): Promise<ConfigurationAudit> {
    const [audit] = await db('configuration_audit')
      .insert({
        tenant_id: tenantId,
        change_type: change.change_type,
        entity_type: change.entity_type,
        entity_key: change.entity_key,
        old_value: change.old_value,
        new_value: change.new_value,
        change_reason: change.change_reason,
        changed_by: change.changed_by,
        ip_address: change.ip_address,
        status: 'completed',
      })
      .returning('*');

    return audit;
  }

  /**
   * Get configuration audit trail
   */
  async getConfigurationAudit(
    tenantId: number,
    options: {
      limit?: number;
      offset?: number;
      entityType?: string;
      startDate?: Date;
      endDate?: Date;
    } = {}
  ): Promise<ConfigurationAudit[]> {
    let query = db('configuration_audit').where({ tenant_id: tenantId });

    if (options.entityType) {
      query = query.where({ entity_type: options.entityType });
    }

    if (options.startDate) {
      query = query.where('created_at', '>=', options.startDate);
    }

    if (options.endDate) {
      query = query.where('created_at', '<=', options.endDate);
    }

    const limit = options.limit || 100;
    const offset = options.offset || 0;

    return query
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);
  }

  /**
   * Get workflow settings for tenant
   */
  async getWorkflowSettings(tenantId: number, workflowKey?: string): Promise<any[]> {
    let query = db('workflow_settings').where({ tenant_id: tenantId });

    if (workflowKey) {
      query = query.where({ workflow_key: workflowKey });
    }

    return query;
  }

  /**
   * Update workflow settings
   */
  async updateWorkflowSettings(
    tenantId: number,
    workflowKey: string,
    settings: any
  ): Promise<any> {
    const existing = await db('workflow_settings')
      .where({ tenant_id: tenantId, workflow_key: workflowKey })
      .first();

    if (!existing) {
      const [created] = await db('workflow_settings')
        .insert({
          tenant_id: tenantId,
          workflow_key: workflowKey,
          workflow_name: settings.workflow_name,
          description: settings.description,
          requires_approval: settings.requires_approval,
          approval_level: settings.approval_level,
          auto_approve_threshold: settings.auto_approve_threshold,
        })
        .returning('*');

      return created;
    }

    const [updated] = await db('workflow_settings')
      .where({ tenant_id: tenantId, workflow_key: workflowKey })
      .update({
        ...settings,
        updated_at: new Date(),
      })
      .returning('*');

    return updated;
  }

  /**
   * Get system default settings
   */
  async getSystemDefaults(): Promise<Record<string, any>> {
    const defaults = await db('system_defaults');
    const result: Record<string, any> = {};

    for (const def of defaults) {
      let value: any = def.setting_value;

      // Parse by data type
      if (def.data_type === 'integer') {
        value = parseInt(value, 10);
      } else if (def.data_type === 'boolean') {
        value = value === 'true' || value === '1' || value === true;
      } else if (def.data_type === 'decimal') {
        value = parseFloat(value);
      }

      result[def.setting_key] = value;
    }

    return result;
  }

  /**
   * Get system default value
   */
  async getSystemDefault(key: string, fallback?: any): Promise<any> {
    const defaults = await this.getSystemDefaults();
    return defaults[key] ?? fallback;
  }

  /**
   * Get configuration summary for tenant
   */
  async getConfigurationSummary(tenantId: number): Promise<any> {
    const settings = await this.getTenantSettings(tenantId);
    const flags = await this.getFeatureFlags(tenantId);
    const integrations = await this.getIntegrationSettings(tenantId);

    const enabledFeatures = flags.filter((f) => f.is_enabled).map((f) => f.feature_key);
    const enabledIntegrations = integrations
      .filter((i) => i.is_enabled)
      .map((i) => i.integration_key);

    return {
      company_name: settings?.company_registration_number,
      timezone: settings?.timezone,
      currency: settings?.currency,
      language: settings?.language,
      features_enabled_count: flags.filter((f) => f.is_enabled).length,
      features_total_count: flags.length,
      enabled_features: enabledFeatures,
      integrations_configured: integrations.filter((i) => i.is_configured).length,
      integrations_enabled: enabledIntegrations,
      invoice_config: {
        prefix: settings?.invoice_prefix,
        next_number: settings?.invoice_start_number,
      },
    };
  }
}

export const configurationService = new ConfigurationService();
