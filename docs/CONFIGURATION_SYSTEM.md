# Configuration & Settings System

## Overview

The Configuration System provides tenant-specific settings management, feature flags, workflow customization, and audit trails for all configuration changes.

## Database Schema

### tenant_settings
Stores company-specific settings for each tenant.

```sql
CREATE TABLE tenant_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER UNIQUE,
  -- Company info
  company_registration_number VARCHAR(255),
  company_tax_id VARCHAR(255),
  company_phone VARCHAR(20),
  company_email VARCHAR(255),
  company_address VARCHAR(500),
  -- Regional settings
  timezone VARCHAR(50) DEFAULT 'Asia/Karachi',
  currency VARCHAR(10) DEFAULT 'PKR',
  language VARCHAR(10) DEFAULT 'ur',
  -- Tax settings
  tax_enabled BOOLEAN DEFAULT TRUE,
  default_tax_rate DECIMAL(5,2) DEFAULT 17.00,
  -- Invoice settings
  invoice_prefix VARCHAR(20) DEFAULT 'INV',
  invoice_start_number INTEGER DEFAULT 1001,
  -- Email settings
  email_from_name VARCHAR(255),
  email_from_address VARCHAR(255),
  smtp_enabled BOOLEAN DEFAULT FALSE,
  -- Notification settings
  send_invoice_notifications BOOLEAN DEFAULT TRUE,
  send_order_notifications BOOLEAN DEFAULT TRUE,
  ...
);
```

### feature_flags
Manages feature availability per tenant.

```sql
CREATE TABLE feature_flags (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  feature_key VARCHAR(100),          -- 'invoicing', 'analytics', 'api_access'
  feature_name VARCHAR(255),
  is_enabled BOOLEAN DEFAULT TRUE,
  category VARCHAR(50),              -- 'core', 'enterprise', 'security'
  max_users INTEGER,
  max_orders INTEGER,
  is_beta BOOLEAN DEFAULT FALSE,
  ...
);
```

### configuration_audit
Audit trail for all configuration changes.

```sql
CREATE TABLE configuration_audit (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  changed_by INTEGER,
  change_type VARCHAR(50),           -- 'create', 'update', 'delete'
  entity_type VARCHAR(100),          -- 'tenant_settings', 'feature_flag'
  entity_key VARCHAR(255),
  old_value TEXT,
  new_value TEXT,
  change_reason VARCHAR(500),
  ip_address VARCHAR(45),
  created_at TIMESTAMP,
  ...
);
```

### workflow_settings
Manages workflow customization per tenant.

```sql
CREATE TABLE workflow_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  workflow_key VARCHAR(100),
  workflow_name VARCHAR(255),
  requires_approval BOOLEAN DEFAULT FALSE,
  approval_level INTEGER DEFAULT 1,
  auto_approve_threshold DECIMAL(12,2),
  notification_on_step_change BOOLEAN DEFAULT TRUE,
  ...
);
```

### integration_settings
Third-party integration configuration.

```sql
CREATE TABLE integration_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  integration_key VARCHAR(100),      -- 'stripe', 'quickbooks', 'slack'
  integration_name VARCHAR(255),
  is_enabled BOOLEAN DEFAULT FALSE,
  is_configured BOOLEAN DEFAULT FALSE,
  api_key VARCHAR(255),
  api_secret VARCHAR(255),
  config_json JSONB,
  last_sync_at TIMESTAMP,
  ...
);
```

### system_defaults
Global fallback settings for the entire system.

```sql
CREATE TABLE system_defaults (
  id SERIAL PRIMARY KEY,
  setting_key VARCHAR(100) UNIQUE,   -- 'session_timeout_minutes', 'max_login_attempts'
  setting_name VARCHAR(255),
  setting_value TEXT,
  data_type VARCHAR(50),
  is_readonly BOOLEAN DEFAULT FALSE,
  ...
);
```

## Backend Services

### ConfigurationService (`services/configuration-service.ts`)

```typescript
// Get tenant settings
const settings = await configurationService.getTenantSettings(tenantId);

// Update settings (automatically logs to audit trail)
const updated = await configurationService.updateTenantSettings(tenantId, {
  company_name: 'Acme Textiles',
  timezone: 'Asia/Karachi',
  default_tax_rate: 17.00
});

// Get all feature flags
const flags = await configurationService.getFeatureFlags(tenantId);

// Check if feature is enabled
const hasAPI = await configurationService.isFeatureEnabled(tenantId, 'api_access');

// Toggle feature (with reason)
await configurationService.updateFeatureFlag(
  tenantId,
  'api_access',
  true,
  'Enabled for enterprise customer'
);

// Get integration settings
const integrations = await configurationService.getIntegrationSettings(tenantId);

// Update integration
await configurationService.updateIntegrationSetting(tenantId, 'stripe', {
  is_enabled: true,
  api_key: 'sk_...'
});

// Get audit trail
const audit = await configurationService.getConfigurationAudit(tenantId, {
  limit: 100,
  entityType: 'tenant_settings',
  startDate: new Date('2026-08-01')
});

// Get configuration summary
const summary = await configurationService.getConfigurationSummary(tenantId);
// Returns: { company_name, timezone, currency, features_enabled_count, ... }
```

## API Endpoints

### Settings Management

**GET /api/v1/configuration/settings**
- Get tenant settings
- Returns: TenantSettings object

**PUT /api/v1/configuration/settings**
- Update tenant settings
- Body: Any partial TenantSettings object
- Returns: Updated settings with success message

### Feature Flags

**GET /api/v1/configuration/features**
- Get all feature flags for tenant
- Returns: `{ total, enabled, features: [...] }`

**GET /api/v1/configuration/features/:featureKey**
- Get specific feature flag
- Returns: FeatureFlag object

**PUT /api/v1/configuration/features/:featureKey**
- Enable/disable feature
- Body: `{ is_enabled: boolean, change_reason?: string }`
- Returns: Updated feature flag

### Integrations

**GET /api/v1/configuration/integrations**
- Get all integration settings
- Returns: `{ total, configured, enabled, integrations: [...] }`

**GET /api/v1/configuration/integrations/:integrationKey**
- Get specific integration
- Returns: IntegrationSetting object

**PUT /api/v1/configuration/integrations/:integrationKey**
- Update integration settings
- Body: Integration configuration
- Returns: Updated integration

### Workflows

**GET /api/v1/configuration/workflows**
- Get all workflow settings
- Returns: Array of workflows

**GET /api/v1/configuration/workflows/:workflowKey**
- Get specific workflow
- Returns: Workflow configuration

**PUT /api/v1/configuration/workflows/:workflowKey**
- Update workflow settings
- Body: Workflow configuration
- Returns: Updated workflow

### Audit & Summary

**GET /api/v1/configuration/audit?limit=100&offset=0&entity_type=tenant_settings**
- Get configuration audit trail
- Query params: `limit`, `offset`, `entity_type`
- Returns: `{ total, limit, offset, audit: [...] }`

**GET /api/v1/configuration/summary**
- Get configuration summary for tenant
- Returns: ConfigurationSummary with enabled features, integrations, etc.

**GET /api/v1/configuration/defaults**
- Get system default settings
- Returns: Record of all system defaults

## Frontend Integration

### useConfiguration Hook

```typescript
import { useConfiguration } from '@/hooks/useConfiguration';

function SettingsDashboard() {
  const { 
    settings, 
    features, 
    integrations,
    summary,
    loading,
    error,
    updateSettings,
    toggleFeature,
    updateIntegration,
    refreshConfiguration
  } = useConfiguration();

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      <h1>{settings?.company_name}</h1>
      <p>Timezone: {settings?.timezone}</p>
      <p>Currency: {settings?.currency}</p>
      
      <h2>Features ({summary?.features_enabled_count}/{summary?.features_total_count})</h2>
      {features.map(feature => (
        <div key={feature.feature_key}>
          <label>
            <input 
              type="checkbox" 
              checked={feature.is_enabled}
              onChange={(e) => toggleFeature(feature.feature_key, e.target.checked)}
            />
            {feature.feature_name}
          </label>
        </div>
      ))}
    </div>
  );
}
```

### useFeatureFlag Hook

```typescript
import { useFeatureFlag } from '@/hooks/useConfiguration';

function APISection() {
  const hasAPIAccess = useFeatureFlag('api_access');

  if (!hasAPIAccess) {
    return <p>API access not enabled. Upgrade to enterprise plan.</p>;
  }

  return <APIConfiguration />;
}
```

### withFeatureFlag HOC

```typescript
import { withFeatureFlag } from '@/hooks/useConfiguration';

const AnalyticsComponent = () => <div>Analytics Dashboard</div>;

export default withFeatureFlag('analytics', <p>Feature not available</p>)(AnalyticsComponent);
```

## Default Features

All new tenants get these features by default:

**Core Features (always enabled):**
- `invoicing` - Invoice creation and management
- `user_management` - Team member management
- `role_based_access` - RBAC for users

**Enterprise Features (disabled by default):**
- `api_access` - REST API access for integrations
- `advanced_reporting` - Custom reports and exports
- `multi_warehouse` - Multiple warehouse management
- `automated_workflows` - Workflow automation

**Security Features:**
- `audit_logs` - Detailed audit trail (enabled by default)
- `two_factor_auth` - 2FA authentication (enabled by default)

## Configuration Audit Trail

Every configuration change is logged with:
- **Who** changed it (user_id)
- **What** changed (entity_type, entity_key, old/new values)
- **When** (timestamp)
- **Why** (change_reason - optional)
- **Where** (ip_address)

Example audit entry:
```json
{
  "id": 1,
  "tenant_id": 1,
  "changed_by": 5,
  "change_type": "update",
  "entity_type": "tenant_settings",
  "entity_key": "default_tax_rate",
  "old_value": "17.00",
  "new_value": "18.00",
  "change_reason": "Updated for new fiscal year",
  "ip_address": "203.0.113.45",
  "created_at": "2026-08-25T18:30:00Z"
}
```

## Workflow Customization

Tenants can customize order/invoice workflows:

```typescript
// Get workflow settings
const orderWorkflow = await configurationService.getWorkflowSettings(
  tenantId, 
  'order-approval'
);

// Update workflow
await configurationService.updateWorkflowSettings(tenantId, 'order-approval', {
  workflow_name: 'Order Approval Process',
  requires_approval: true,
  approval_level: 2,
  auto_approve_threshold: 50000.00,
  notification_on_step_change: true
});
```

## Integration Management

Tenants can manage third-party integrations:

**Supported Integrations:**
- Stripe (payment processing)
- QuickBooks (accounting)
- Slack (notifications)
- Zapier (workflow automation)

```typescript
// Configure Stripe
await configurationService.updateIntegrationSetting(tenantId, 'stripe', {
  is_enabled: true,
  is_configured: true,
  api_key: 'sk_live_...',
  config_json: { publishable_key: 'pk_live_...' }
});

// Sync integration
const integration = await configurationService.getIntegrationSetting(
  tenantId,
  'stripe'
);
console.log(integration.last_sync_at); // Last sync timestamp
```

## System Defaults

Global defaults used as fallback:

```typescript
const defaults = await configurationService.getSystemDefaults();
// {
//   'session_timeout_minutes': 30,
//   'password_min_length': 8,
//   'max_login_attempts': 5,
//   'default_invoice_terms': '30 days',
//   ...
// }

// Get single default
const sessionTimeout = await configurationService.getSystemDefault(
  'session_timeout_minutes',
  30  // fallback
);
```

## Configuration Summary

Get complete configuration overview:

```typescript
const summary = await configurationService.getConfigurationSummary(tenantId);
// {
//   company_name: 'TKT Textiles',
//   timezone: 'Asia/Karachi',
//   currency: 'PKR',
//   language: 'ur',
//   features_enabled_count: 7,
//   features_total_count: 10,
//   enabled_features: ['invoicing', 'analytics', 'audit_logs', ...],
//   integrations_configured: 2,
//   integrations_enabled: ['stripe', 'slack'],
//   invoice_config: { prefix: 'INV', next_number: 1001 }
// }
```

## Security Considerations

✅ **Tenant Isolation** - Settings isolated by tenant_id  
✅ **Audit Trail** - All changes tracked with user and IP  
✅ **Change Reasons** - Optional notes for compliance  
✅ **Read-Only Settings** - System defaults marked as readonly  
✅ **API Key Encryption** - Integration credentials encrypted in production  

## Performance Tips

1. **Cache configuration** - Frontend caches config on load
2. **Lazy load features** - Load feature flags on demand
3. **Batch updates** - Update multiple settings in one request
4. **Cleanup audit** - Archive old audit logs (>1 year)

## Troubleshooting

**Feature not showing as enabled?**
- Check audit trail for disable events
- Verify tenant_id in feature_flags table
- Refresh configuration hook

**Settings not persisting?**
- Check for validation errors in response
- Verify user has admin role
- Check database connection

**Audit trail not recording?**
- Verify configuration_audit table exists
- Check for database permission issues
- Look for constraint violations

## Migration from Single-Tenant

If migrating from single-tenant TKT:

1. Create tenant_settings for tenant_id=1
2. Seed feature_flags for tenant_id=1
3. Create workflow_settings templates
4. Set up integration configurations
5. Configure system defaults

Example:

```sql
INSERT INTO tenant_settings (tenant_id, company_name, timezone, currency, ...)
VALUES (1, 'TKT Textiles', 'Asia/Karachi', 'PKR', ...);

INSERT INTO feature_flags (tenant_id, feature_key, feature_name, is_enabled, ...)
VALUES (1, 'invoicing', 'Invoicing Module', true, ...);
```

## Related Documentation

- [Multi-Tenancy Architecture](./MULTI_TENANCY.md)
- [White-Labeling System](./BRANDING_SYSTEM.md)
- [API Documentation](./API.md)
- [Authentication & Authorization](./AUTH_SYSTEM.md)
