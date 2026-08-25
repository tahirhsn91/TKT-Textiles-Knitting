-- Migration: Add configuration and settings system for multi-tenant customization
-- Purpose: Enable tenant-specific settings, feature flags, and audit trail
-- Date: 2026-08-25

-- 1. Create tenant_settings table for company-specific settings
CREATE TABLE IF NOT EXISTS tenant_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL UNIQUE,
  -- Basic company info
  company_registration_number VARCHAR(255),
  company_tax_id VARCHAR(255),
  company_bank_account VARCHAR(255),
  company_phone VARCHAR(20),
  company_email VARCHAR(255),
  company_website VARCHAR(255),
  company_address VARCHAR(500),
  company_city VARCHAR(100),
  company_province VARCHAR(100),
  company_postal_code VARCHAR(20),
  company_country VARCHAR(100) DEFAULT 'Pakistan',
  
  -- Business settings
  business_type VARCHAR(100),
  industry_category VARCHAR(100),
  employee_count INTEGER,
  annual_revenue BIGINT,
  fiscal_year_start DATE,
  fiscal_year_end DATE,
  
  -- Regional settings
  timezone VARCHAR(50) DEFAULT 'Asia/Karachi',
  currency VARCHAR(10) DEFAULT 'PKR',
  language VARCHAR(10) DEFAULT 'ur',
  date_format VARCHAR(20) DEFAULT 'DD/MM/YYYY',
  number_format VARCHAR(20) DEFAULT '1,234.56',
  
  -- Tax settings
  tax_enabled BOOLEAN DEFAULT TRUE,
  default_tax_rate DECIMAL(5,2) DEFAULT 17.00,
  tax_method VARCHAR(50) DEFAULT 'inclusive',
  tax_number_format VARCHAR(50) DEFAULT 'GST',
  
  -- Invoice settings
  invoice_prefix VARCHAR(20) DEFAULT 'INV',
  invoice_start_number INTEGER DEFAULT 1001,
  invoice_logo_position VARCHAR(50) DEFAULT 'left',
  invoice_terms_conditions TEXT,
  invoice_payment_instructions TEXT,
  
  -- Email settings
  email_from_name VARCHAR(255),
  email_from_address VARCHAR(255),
  email_reply_to VARCHAR(255),
  smtp_enabled BOOLEAN DEFAULT FALSE,
  smtp_host VARCHAR(255),
  smtp_port INTEGER DEFAULT 587,
  smtp_username VARCHAR(255),
  smtp_password VARCHAR(255),
  smtp_use_tls BOOLEAN DEFAULT TRUE,
  
  -- Notification settings
  send_invoice_notifications BOOLEAN DEFAULT TRUE,
  send_order_notifications BOOLEAN DEFAULT TRUE,
  send_payment_notifications BOOLEAN DEFAULT TRUE,
  send_production_alerts BOOLEAN DEFAULT TRUE,
  
  -- General settings
  app_name VARCHAR(255),
  support_email VARCHAR(255),
  support_phone VARCHAR(20),
  privacy_policy_url VARCHAR(500),
  terms_conditions_url VARCHAR(500),
  
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_tenant_settings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tenant_settings_tenant_id ON tenant_settings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_settings_status ON tenant_settings(status);

-- 2. Create feature_flags table for feature management
CREATE TABLE IF NOT EXISTS feature_flags (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  feature_key VARCHAR(100) NOT NULL,
  feature_name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Feature control
  is_enabled BOOLEAN DEFAULT TRUE,
  is_beta BOOLEAN DEFAULT FALSE,
  
  -- Categories
  category VARCHAR(50),
  
  -- Limits
  max_users INTEGER,
  max_orders INTEGER,
  max_storage_mb INTEGER,
  max_api_calls_per_month INTEGER,
  
  -- Dates
  enabled_at TIMESTAMP,
  disabled_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_feature_flags_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT uq_feature_flags_key UNIQUE(tenant_id, feature_key)
);

CREATE INDEX IF NOT EXISTS idx_feature_flags_tenant ON feature_flags(tenant_id);
CREATE INDEX IF NOT EXISTS idx_feature_flags_enabled ON feature_flags(tenant_id, is_enabled);
CREATE INDEX IF NOT EXISTS idx_feature_flags_category ON feature_flags(tenant_id, category);

-- 3. Create configuration_audit table for audit trail
CREATE TABLE IF NOT EXISTS configuration_audit (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  changed_by INTEGER,
  change_type VARCHAR(50),
  entity_type VARCHAR(100),
  entity_key VARCHAR(255),
  old_value TEXT,
  new_value TEXT,
  change_reason VARCHAR(500),
  ip_address VARCHAR(45),
  user_agent TEXT,
  status VARCHAR(50) DEFAULT 'completed',
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_config_audit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_config_audit_user FOREIGN KEY (changed_by) REFERENCES app_user(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_config_audit_tenant ON configuration_audit(tenant_id);
CREATE INDEX IF NOT EXISTS idx_config_audit_date ON configuration_audit(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_config_audit_user ON configuration_audit(changed_by);
CREATE INDEX IF NOT EXISTS idx_config_audit_entity ON configuration_audit(tenant_id, entity_type);

-- 4. Create workflow_settings table for process customization
CREATE TABLE IF NOT EXISTS workflow_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  workflow_key VARCHAR(100) NOT NULL,
  workflow_name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Workflow configuration
  requires_approval BOOLEAN DEFAULT FALSE,
  approval_level INTEGER DEFAULT 1,
  auto_approve_threshold DECIMAL(12,2),
  notification_on_step_change BOOLEAN DEFAULT TRUE,
  
  -- Steps
  step_sequence TEXT,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_workflow_settings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT uq_workflow_settings_key UNIQUE(tenant_id, workflow_key)
);

CREATE INDEX IF NOT EXISTS idx_workflow_settings_tenant ON workflow_settings(tenant_id);

-- 5. Create integration_settings table for third-party integrations
CREATE TABLE IF NOT EXISTS integration_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  integration_key VARCHAR(100) NOT NULL,
  integration_name VARCHAR(255) NOT NULL,
  description TEXT,
  
  -- Integration status
  is_enabled BOOLEAN DEFAULT FALSE,
  is_configured BOOLEAN DEFAULT FALSE,
  
  -- Credentials (encrypted in production)
  api_key VARCHAR(255),
  api_secret VARCHAR(255),
  webhook_url VARCHAR(500),
  webhook_secret VARCHAR(255),
  
  -- Configuration
  config_json JSONB,
  
  -- Metadata
  last_sync_at TIMESTAMP,
  last_error_message TEXT,
  error_count INTEGER DEFAULT 0,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_integration_settings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT uq_integration_settings_key UNIQUE(tenant_id, integration_key)
);

CREATE INDEX IF NOT EXISTS idx_integration_settings_tenant ON integration_settings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_integration_settings_enabled ON integration_settings(tenant_id, is_enabled);

-- 6. Create system_defaults table for global fallback settings
CREATE TABLE IF NOT EXISTS system_defaults (
  id SERIAL PRIMARY KEY,
  setting_key VARCHAR(100) NOT NULL UNIQUE,
  setting_name VARCHAR(255) NOT NULL,
  setting_value TEXT,
  data_type VARCHAR(50),
  description TEXT,
  is_readonly BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_system_defaults_key ON system_defaults(setting_key);

-- 7. Seed default tenant settings for TKT Textiles (tenant_id = 1)
INSERT INTO tenant_settings (
  tenant_id,
  company_registration_number,
  company_tax_id,
  company_phone,
  company_email,
  company_address,
  company_city,
  company_country,
  business_type,
  industry_category,
  timezone,
  currency,
  language,
  tax_enabled,
  default_tax_rate,
  invoice_prefix,
  invoice_start_number,
  email_from_name,
  email_from_address,
  app_name
)
VALUES (
  1,
  'TKT-001',
  'GST-123456789',
  '+923200000000',
  'info@tkttextiles.com',
  'TKT Complex, Karachi',
  'Karachi',
  'Pakistan',
  'Manufacturing',
  'Textile & Knitting',
  'Asia/Karachi',
  'PKR',
  'ur',
  TRUE,
  17.00,
  'INV',
  1001,
  'TKT Textiles',
  'noreply@tkttextiles.com',
  'TKT Textiles'
)
ON CONFLICT (tenant_id) DO NOTHING;

-- 8. Seed default feature flags
INSERT INTO feature_flags (tenant_id, feature_key, feature_name, description, category, is_enabled)
VALUES 
  (1, 'invoicing', 'Invoicing Module', 'Enable invoice creation and management', 'core', TRUE),
  (1, 'analytics', 'Analytics Dashboard', 'Enable analytics and reporting', 'core', TRUE),
  (1, 'api_access', 'API Access', 'Enable REST API access for integrations', 'enterprise', FALSE),
  (1, 'advanced_reporting', 'Advanced Reporting', 'Enable custom reports and exports', 'enterprise', FALSE),
  (1, 'multi_warehouse', 'Multi-Warehouse', 'Enable multiple warehouse management', 'enterprise', FALSE),
  (1, 'automated_workflows', 'Automated Workflows', 'Enable workflow automation', 'enterprise', FALSE),
  (1, 'audit_logs', 'Audit Logs', 'Enable detailed audit trail', 'enterprise', TRUE),
  (1, 'user_management', 'User Management', 'Enable team member management', 'core', TRUE),
  (1, 'role_based_access', 'Role-Based Access Control', 'Enable RBAC for users', 'core', TRUE),
  (1, 'two_factor_auth', '2FA Authentication', 'Enable two-factor authentication', 'security', TRUE)
ON CONFLICT (tenant_id, feature_key) DO NOTHING;

-- 9. Seed system defaults
INSERT INTO system_defaults (setting_key, setting_name, setting_value, data_type, description)
VALUES 
  ('session_timeout_minutes', 'Session Timeout', '30', 'integer', 'User session timeout in minutes'),
  ('password_min_length', 'Min Password Length', '8', 'integer', 'Minimum password length'),
  ('password_require_uppercase', 'Require Uppercase', 'true', 'boolean', 'Require uppercase in passwords'),
  ('password_require_special', 'Require Special Char', 'true', 'boolean', 'Require special characters in passwords'),
  ('max_login_attempts', 'Max Login Attempts', '5', 'integer', 'Max failed login attempts before lockout'),
  ('lockout_duration_minutes', 'Lockout Duration', '15', 'integer', 'Account lockout duration in minutes'),
  ('default_invoice_terms', 'Default Invoice Terms', '30 days', 'string', 'Default payment terms'),
  ('default_discount_percentage', 'Default Discount', '0', 'decimal', 'Default discount percentage'),
  ('system_timezone', 'System Timezone', 'Asia/Karachi', 'string', 'System default timezone'),
  ('system_currency', 'System Currency', 'PKR', 'string', 'System default currency')
ON CONFLICT (setting_key) DO NOTHING;

-- 10. Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_config_audit_tenant_date ON configuration_audit(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feature_flags_tenant_enabled ON feature_flags(tenant_id, is_enabled);
CREATE INDEX IF NOT EXISTS idx_integration_settings_sync ON integration_settings(tenant_id, last_sync_at);

COMMIT;
