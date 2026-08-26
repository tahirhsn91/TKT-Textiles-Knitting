-- Migration: 0027_reconcile_multi_tenant_schema
-- Purpose: Bring a DB restored from an OLD backup (at migration 0021) up to the
--          multi-tenant schema that the current Drizzle schema (source of truth)
--          requires. The historical 0022-0026 SQL files are stale/diverge from
--          the real schema (they create dead tables and miss the real ones), so
--          this migration is the schema-accurate reconciliation:
--            * create `tenants` + seed tenant 1
--            * add nullable `tenant_id` to app_user / role (super-admin = NULL)
--            * add `tenant_id NOT NULL DEFAULT 1` to all business tables
--            * create the real tenant-scoped tables (settings/branding/flags/
--              presets/sessions/oauth/audit-log/api-keys/invitations)
--            * re-point role/app_user uniques to tenant-scoped composite keys
--            * seed tenant-1 roles, RBAC, branding, settings, flags, sessions
-- Date: 2026-08-26
-- Idempotent: safe to run on a DB that already has these objects (IF NOT EXISTS).

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Tenants table + default tenant
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tenants (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  industry TEXT,
  country TEXT DEFAULT 'Pakistan',
  timezone TEXT DEFAULT 'Asia/Karachi',
  currency TEXT DEFAULT 'PKR',
  language TEXT DEFAULT 'ur',
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  metadata JSONB
);
CREATE UNIQUE INDEX IF NOT EXISTS tenants_name_key ON tenants(name);
CREATE UNIQUE INDEX IF NOT EXISTS tenants_slug_key ON tenants(slug);

INSERT INTO tenants (id, name, slug, industry, country, timezone, currency, language, status)
VALUES (1, 'TKT Textiles', 'tkt-textiles', 'Textile & Knitting', 'Pakistan', 'Asia/Karachi', 'PKR', 'ur', 'active')
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. tenant_id on app_user / role (NULLABLE — super-admin stays global)
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE;
ALTER TABLE role ADD COLUMN IF NOT EXISTS tenant_id INTEGER REFERENCES tenants(id) ON DELETE CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. tenant_id NOT NULL DEFAULT 1 on all business tables
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE department_master       ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE employee_advances       ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE employee_master         ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE employee_salary_records ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE employee_salary_settings ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE fabric_type_master      ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE job_master              ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE location_master         ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE machine_master          ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE party_master            ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE salary_detail           ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE salary_header           ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE transaction_type_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE uom_master              ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_brand_master       ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_count_master       ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_type_master        ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE attendance              ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE machine_history         ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE transaction_detail      ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE transaction_header      ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE daily_production_detail ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE daily_production_header ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_receipt_detail     ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_receipt_header     ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE daily_delivery          ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE configuration           ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE plausibility_baseline   ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE plausibility_feedback   ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE machine_maintenance     ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE factory_maintenance     ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE company_info_master     ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE invoice_item            ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE invoice_payment         ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE invoice                 ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE invoice_transaction     ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;

-- FKs to tenants (cascade on delete for business tables)
DO $$
DECLARE t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'department_master','employee_advances','employee_master','employee_salary_records',
    'employee_salary_settings','fabric_type_master','job_master','location_master',
    'machine_master','party_master','salary_detail','salary_header',
    'transaction_type_master','uom_master','yarn_brand_master','yarn_count_master',
    'yarn_type_master','attendance','machine_history','transaction_detail',
    'transaction_header','daily_production_detail','daily_production_header',
    'yarn_receipt_detail','yarn_receipt_header','daily_delivery','configuration',
    'plausibility_baseline','plausibility_feedback','machine_maintenance',
    'factory_maintenance','company_info_master','invoice_item','invoice_payment',
    'invoice','invoice_transaction'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint
      WHERE conrelid = format('"%s"', t)::regclass
        AND contype = 'f' AND conname = format('fk_%s_tenant', t)
    ) THEN
      EXECUTE format('ALTER TABLE "%s" ADD CONSTRAINT fk_%s_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE', t, t);
    END IF;
  END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Re-point role / app_user uniques to tenant-scoped composite keys
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE role DROP CONSTRAINT IF EXISTS role_name_unique;
DROP INDEX IF EXISTS role_name_idx;
CREATE UNIQUE INDEX IF NOT EXISTS role_name_idx ON role(name, tenant_id);

ALTER TABLE app_user DROP CONSTRAINT IF EXISTS app_user_username_unique;
DROP INDEX IF EXISTS user_username_idx;
CREATE UNIQUE INDEX IF NOT EXISTS user_username_idx ON app_user(username, tenant_id);

-- helper index for tenant lookups
CREATE INDEX IF NOT EXISTS idx_app_user_tenant_id ON app_user(tenant_id);
CREATE INDEX IF NOT EXISTS idx_role_tenant_id ON role(tenant_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Real tenant-scoped tables (per Drizzle schema)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tenant_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  company_registration_number TEXT,
  company_tax_id TEXT,
  company_bank_account TEXT,
  company_phone TEXT,
  company_email TEXT,
  company_website TEXT,
  company_address TEXT,
  company_city TEXT,
  company_province TEXT,
  company_postal_code TEXT,
  company_country TEXT DEFAULT 'Pakistan',
  business_type TEXT,
  industry_category TEXT,
  employee_count INTEGER,
  annual_revenue BIGINT,
  fiscal_year_start DATE,
  fiscal_year_end DATE,
  timezone TEXT DEFAULT 'Asia/Karachi',
  currency TEXT DEFAULT 'PKR',
  language TEXT DEFAULT 'ur',
  date_format TEXT DEFAULT 'DD/MM/YYYY',
  number_format TEXT DEFAULT '1,234.56',
  tax_enabled BOOLEAN DEFAULT TRUE,
  default_tax_rate NUMERIC(5,2) DEFAULT 17.00,
  tax_method TEXT DEFAULT 'inclusive'
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_tenant_settings_tenant ON tenant_settings(tenant_id);

CREATE TABLE IF NOT EXISTS branding_config (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  company_short_name TEXT,
  logo_url TEXT,
  logo_filename TEXT,
  logo_storage_path TEXT,
  favicon_url TEXT,
  primary_color TEXT DEFAULT '#1F2937',
  secondary_color TEXT DEFAULT '#3B82F6',
  accent_color TEXT DEFAULT '#F59E0B',
  text_color TEXT DEFAULT '#111827',
  background_color TEXT DEFAULT '#FFFFFF',
  border_color TEXT DEFAULT '#E5E7EB',
  navbar_background TEXT DEFAULT '#1F2937',
  navbar_text_color TEXT DEFAULT '#FFFFFF',
  sidebar_background TEXT DEFAULT '#F9FAFB',
  sidebar_text_color TEXT DEFAULT '#111827',
  accent_hover_color TEXT,
  success_color TEXT DEFAULT '#10B981',
  warning_color TEXT DEFAULT '#F59E0B',
  error_color TEXT DEFAULT '#EF4444',
  info_color TEXT DEFAULT '#3B82F6',
  font_family TEXT DEFAULT 'Inter, sans-serif',
  font_size_base INTEGER DEFAULT 16,
  border_radius INTEGER DEFAULT 6,
  button_style TEXT DEFAULT 'rounded'
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_branding_config_tenant ON branding_config(tenant_id);

CREATE TABLE IF NOT EXISTS feature_flags (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  feature_name TEXT NOT NULL,
  description TEXT,
  is_enabled BOOLEAN DEFAULT TRUE,
  is_beta BOOLEAN DEFAULT FALSE,
  category TEXT,
  max_users INTEGER,
  max_orders INTEGER,
  max_storage_mb INTEGER,
  max_api_calls_per_month INTEGER,
  enabled_at TIMESTAMP,
  disabled_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_feature_flags_key ON feature_flags(tenant_id, feature_key);
CREATE INDEX IF NOT EXISTS idx_feature_flags_tenant ON feature_flags(tenant_id);
CREATE INDEX IF NOT EXISTS idx_feature_flags_tenant_enabled ON feature_flags(tenant_id, is_enabled);
CREATE INDEX IF NOT EXISTS idx_feature_flags_category ON feature_flags(tenant_id, category);

CREATE TABLE IF NOT EXISTS theme_presets (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  preset_name TEXT NOT NULL,
  preset_key TEXT NOT NULL,
  description TEXT,
  primary_color TEXT,
  secondary_color TEXT,
  accent_color TEXT,
  text_color TEXT,
  background_color TEXT,
  navbar_color TEXT,
  navbar_text_color TEXT,
  sidebar_color TEXT,
  sidebar_text_color TEXT,
  accent_hover_color TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_theme_preset_key ON theme_presets(tenant_id, preset_key);
CREATE INDEX IF NOT EXISTS idx_theme_preset_tenant ON theme_presets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_theme_preset_default ON theme_presets(tenant_id, is_default);

CREATE TABLE IF NOT EXISTS session_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  session_timeout_minutes INTEGER DEFAULT 30,
  remember_me_enabled BOOLEAN DEFAULT TRUE,
  remember_me_duration_days INTEGER DEFAULT 30,
  max_concurrent_sessions INTEGER DEFAULT 5,
  force_password_change_days INTEGER DEFAULT 90,
  password_expiry_enabled BOOLEAN DEFAULT FALSE,
  two_factor_required_for_admins BOOLEAN DEFAULT TRUE,
  two_factor_optional_for_users BOOLEAN DEFAULT FALSE,
  device_management_enabled BOOLEAN DEFAULT TRUE,
  max_devices_per_user INTEGER DEFAULT 5,
  ip_whitelist_enabled BOOLEAN DEFAULT FALSE,
  ip_whitelist TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS session_settings_tenant_id_key ON session_settings(tenant_id);

CREATE TABLE IF NOT EXISTS oauth_providers (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  provider_name TEXT NOT NULL,
  provider_type TEXT,
  client_id TEXT,
  client_secret TEXT,
  redirect_uri TEXT,
  scope TEXT,
  is_enabled BOOLEAN DEFAULT FALSE,
  is_configured BOOLEAN DEFAULT FALSE,
  config_json JSONB,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_oauth_provider ON oauth_providers(tenant_id, provider_name);
CREATE INDEX IF NOT EXISTS idx_oauth_providers_tenant ON oauth_providers(tenant_id, is_enabled);

CREATE TABLE IF NOT EXISTS audit_log (
  id SERIAL PRIMARY KEY,
  actor_user_id INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
  actor_tenant_id INTEGER REFERENCES tenants(id) ON DELETE SET NULL,
  target_tenant_id INTEGER REFERENCES tenants(id) ON DELETE SET NULL,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100),
  entity_id INTEGER,
  description TEXT,
  before_json JSONB,
  after_json JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON audit_log(actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_target_tenant ON audit_log(target_tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log(action);
CREATE INDEX IF NOT EXISTS idx_audit_log_created ON audit_log(created_at);

CREATE TABLE IF NOT EXISTS api_keys (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  label VARCHAR(120) NOT NULL,
  key_hash VARCHAR(128) NOT NULL,
  key_hint VARCHAR(16) NOT NULL,
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_by INTEGER,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS user_invitations (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  invited_by INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
  email TEXT NOT NULL,
  role TEXT DEFAULT 'Manager' NOT NULL,
  token TEXT NOT NULL,
  status TEXT DEFAULT 'pending' NOT NULL,
  accepted_by INTEGER REFERENCES app_user(id) ON DELETE SET NULL,
  accepted_at TIMESTAMP,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_invitations_tenant ON user_invitations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON user_invitations(status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Seed tenant-1 roles + super-admin (global) + RBAC
-- ─────────────────────────────────────────────────────────────────────────────
-- super-admin is GLOBAL (tenant_id NULL). Tenant roles get tenant_id 1.
INSERT INTO role (name, is_admin, tenant_id)
SELECT 'super-admin', TRUE, NULL
WHERE NOT EXISTS (SELECT 1 FROM role WHERE name = 'super-admin' AND tenant_id IS NULL);

UPDATE role SET tenant_id = 1 WHERE tenant_id IS NULL AND name IN ('Admin','Manager','Supervisor');

-- Make sure Admin/Manager/Supervisor exist for tenant 1 with matching is_admin flag
INSERT INTO role (name, is_admin, tenant_id)
VALUES ('Admin', TRUE, 1), ('Manager', FALSE, 1), ('Supervisor', FALSE, 1)
ON CONFLICT DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Assign users to tenant 1 (super-admin admin stays global)
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE app_user SET tenant_id = 1 WHERE tenant_id IS NULL;
-- admin = global super-admin (tenant NULL). Ensure admin has the super-admin role.
UPDATE role SET is_admin = TRUE WHERE name = 'super-admin';
UPDATE app_user SET tenant_id = NULL, role_id = (SELECT id FROM role WHERE name = 'super-admin' AND tenant_id IS NULL LIMIT 1)
WHERE username = 'admin';

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. Seed tenant-1 branding / settings / feature flags / session settings
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO tenant_settings (tenant_id, company_registration_number, company_tax_id, company_phone,
  company_email, company_address, company_city, company_country, business_type, industry_category,
  timezone, currency, language, tax_enabled, default_tax_rate)
VALUES (1, 'TKT-001', 'GST-123456789', '+923200000000', 'info@tkttextiles.com', 'TKT Complex, Karachi',
  'Karachi', 'Pakistan', 'Manufacturing', 'Textile & Knitting', 'Asia/Karachi', 'PKR', 'ur', TRUE, 17.00)
ON CONFLICT (tenant_id) DO NOTHING;

INSERT INTO branding_config (tenant_id, company_name, company_short_name,
  primary_color, secondary_color, accent_color, text_color, background_color,
  navbar_background, navbar_text_color, sidebar_background, sidebar_text_color)
SELECT 1, 'TKT Textiles', 'TKT', '#1F2937', '#3B82F6', '#F59E0B', '#111827', '#FFFFFF',
       '#1F2937', '#FFFFFF', '#F9FAFB', '#111827'
WHERE NOT EXISTS (SELECT 1 FROM branding_config WHERE tenant_id = 1);

INSERT INTO session_settings (tenant_id, session_timeout_minutes, remember_me_enabled,
  max_concurrent_sessions, two_factor_required_for_admins, device_management_enabled)
VALUES (1, 30, TRUE, 5, TRUE, TRUE)
ON CONFLICT (tenant_id) DO NOTHING;

INSERT INTO feature_flags (tenant_id, feature_key, feature_name, description, category, is_enabled)
SELECT * FROM (VALUES
  (1, 'invoicing', 'Invoicing Module', 'Enable invoice creation and management', 'core', TRUE),
  (1, 'analytics', 'Analytics Dashboard', 'Enable analytics and reporting', 'core', TRUE),
  (1, 'audit_logs', 'Audit Logs', 'Enable detailed audit trail', 'enterprise', TRUE),
  (1, 'user_management', 'User Management', 'Enable team member management', 'core', TRUE),
  (1, 'role_based_access', 'Role-Based Access Control', 'Enable RBAC for users', 'core', TRUE)
) AS v(tenant_id, feature_key, feature_name, description, category, is_enabled)
WHERE NOT EXISTS (SELECT 1 FROM feature_flags WHERE tenant_id = 1);

-- default RBAC permissions for Manager / Supervisor (tenant 1 roles)
INSERT INTO role_permission (role_id, module_id)
SELECT r.id, m
FROM role r
CROSS JOIN (SELECT unnest(ARRAY['dashboard','transactions','dailyProduction','yarnReceipts','dailyDeliveries','payroll','reports','maintenance']) AS m) perm
WHERE r.name = 'Manager' AND r.tenant_id = 1
  AND NOT EXISTS (SELECT 1 FROM role_permission rp WHERE rp.role_id = r.id AND rp.module_id = perm.m);

INSERT INTO role_permission (role_id, module_id)
SELECT r.id, m
FROM role r
CROSS JOIN (SELECT unnest(ARRAY['dashboard','dailyProduction','yarnReceipts','dailyDeliveries','maintenance']) AS m) perm
WHERE r.name = 'Supervisor' AND r.tenant_id = 1
  AND NOT EXISTS (SELECT 1 FROM role_permission rp WHERE rp.role_id = r.id AND rp.module_id = perm.m);

-- backfill business tables tenant_id default to 1 (defensive; col default already 1)
UPDATE department_master       SET tenant_id = 1 WHERE tenant_id IS NULL;

COMMIT;
