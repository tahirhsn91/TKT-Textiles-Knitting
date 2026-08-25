-- Migration: Add branding configuration tables for white-labeling
-- Purpose: Enable multi-tenant white-labeling with dynamic company branding
-- Date: 2026-08-25

-- 1. Create branding_config table for tenant-specific branding
CREATE TABLE IF NOT EXISTS branding_config (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL UNIQUE,
  company_name VARCHAR(255) NOT NULL,
  company_short_name VARCHAR(50),
  logo_url VARCHAR(500),
  logo_filename VARCHAR(255),
  logo_storage_path VARCHAR(500),
  favicon_url VARCHAR(500),
  primary_color VARCHAR(7) DEFAULT '#1F2937',
  secondary_color VARCHAR(7) DEFAULT '#3B82F6',
  accent_color VARCHAR(7) DEFAULT '#F59E0B',
  text_color VARCHAR(7) DEFAULT '#111827',
  background_color VARCHAR(7) DEFAULT '#FFFFFF',
  border_color VARCHAR(7) DEFAULT '#E5E7EB',
  navbar_background VARCHAR(7) DEFAULT '#1F2937',
  navbar_text_color VARCHAR(7) DEFAULT '#FFFFFF',
  sidebar_background VARCHAR(7) DEFAULT '#F9FAFB',
  sidebar_text_color VARCHAR(7) DEFAULT '#111827',
  accent_hover_color VARCHAR(7),
  success_color VARCHAR(7) DEFAULT '#10B981',
  warning_color VARCHAR(7) DEFAULT '#F59E0B',
  error_color VARCHAR(7) DEFAULT '#EF4444',
  info_color VARCHAR(7) DEFAULT '#3B82F6',
  font_family VARCHAR(255) DEFAULT 'Inter, sans-serif',
  font_size_base INTEGER DEFAULT 16,
  border_radius INTEGER DEFAULT 6,
  button_style VARCHAR(50) DEFAULT 'rounded',
  custom_css TEXT,
  email_logo_url VARCHAR(500),
  email_header_color VARCHAR(7),
  email_footer_color VARCHAR(7),
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_branding_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_branding_tenant_id ON branding_config(tenant_id);
CREATE INDEX IF NOT EXISTS idx_branding_status ON branding_config(status);

-- 2. Create email_templates table for white-labeled emails
CREATE TABLE IF NOT EXISTS email_templates (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  template_key VARCHAR(100) NOT NULL,
  template_name VARCHAR(255) NOT NULL,
  subject_line VARCHAR(500),
  template_html TEXT,
  template_text TEXT,
  header_color VARCHAR(7),
  footer_color VARCHAR(7),
  include_logo BOOLEAN DEFAULT TRUE,
  include_footer BOOLEAN DEFAULT TRUE,
  custom_footer_text TEXT,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_email_template_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT uq_email_template_key UNIQUE(tenant_id, template_key)
);

CREATE INDEX IF NOT EXISTS idx_email_template_tenant ON email_templates(tenant_id);
CREATE INDEX IF NOT EXISTS idx_email_template_key ON email_templates(tenant_id, template_key);

-- 3. Create theme_presets table for quick theme selection
CREATE TABLE IF NOT EXISTS theme_presets (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  preset_name VARCHAR(100) NOT NULL,
  preset_key VARCHAR(50) NOT NULL,
  description TEXT,
  primary_color VARCHAR(7),
  secondary_color VARCHAR(7),
  accent_color VARCHAR(7),
  text_color VARCHAR(7),
  background_color VARCHAR(7),
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_theme_preset_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT uq_theme_preset_key UNIQUE(tenant_id, preset_key)
);

CREATE INDEX IF NOT EXISTS idx_theme_preset_tenant ON theme_presets(tenant_id);
CREATE INDEX IF NOT EXISTS idx_theme_preset_default ON theme_presets(tenant_id, is_default);

-- 4. Create logo_uploads table for logo management
CREATE TABLE IF NOT EXISTS logo_uploads (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  filename VARCHAR(255) NOT NULL,
  original_filename VARCHAR(255),
  file_type VARCHAR(50),
  file_size INTEGER,
  storage_url VARCHAR(500),
  storage_path VARCHAR(500),
  storage_provider VARCHAR(50) DEFAULT 'local',
  width INTEGER,
  height INTEGER,
  logo_type VARCHAR(50) DEFAULT 'primary',
  is_active BOOLEAN DEFAULT FALSE,
  uploaded_by INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_logo_uploads_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_logo_uploads_user FOREIGN KEY (uploaded_by) REFERENCES app_user(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_logo_uploads_tenant ON logo_uploads(tenant_id);
CREATE INDEX IF NOT EXISTS idx_logo_uploads_active ON logo_uploads(tenant_id, is_active);
CREATE INDEX IF NOT EXISTS idx_logo_uploads_type ON logo_uploads(tenant_id, logo_type);

-- 5. Create custom_domains table for future multi-domain support
CREATE TABLE IF NOT EXISTS custom_domains (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL UNIQUE,
  domain_name VARCHAR(255) NOT NULL UNIQUE,
  is_primary BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  verification_code VARCHAR(255),
  verified_at TIMESTAMP,
  ssl_certificate_path VARCHAR(500),
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_custom_domain_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_custom_domain_tenant ON custom_domains(tenant_id);
CREATE INDEX IF NOT EXISTS idx_custom_domain_name ON custom_domains(domain_name);

-- 6. Seed default branding config for TKT Textiles (tenant_id = 1)
INSERT INTO branding_config (
  tenant_id,
  company_name,
  company_short_name,
  primary_color,
  secondary_color,
  accent_color,
  text_color,
  background_color,
  navbar_background,
  navbar_text_color,
  sidebar_background,
  sidebar_text_color,
  status
)
VALUES (
  1,
  'TKT Textiles',
  'TKT',
  '#1F2937',
  '#3B82F6',
  '#F59E0B',
  '#111827',
  '#FFFFFF',
  '#1F2937',
  '#FFFFFF',
  '#F9FAFB',
  '#111827',
  'active'
)
ON CONFLICT (tenant_id) DO NOTHING;

-- 7. Create theme presets for default tenant
INSERT INTO theme_presets (tenant_id, preset_name, preset_key, primary_color, secondary_color, accent_color, is_default)
VALUES 
  (1, 'Classic Blue', 'classic-blue', '#1F2937', '#3B82F6', '#F59E0B', TRUE),
  (1, 'Modern Dark', 'modern-dark', '#0F172A', '#1E293B', '#64748B', FALSE),
  (1, 'Professional', 'professional', '#003366', '#0066CC', '#FF9900', FALSE),
  (1, 'Minimal Green', 'minimal-green', '#065F46', '#10B981', '#34D399', FALSE)
ON CONFLICT (tenant_id, preset_key) DO NOTHING;

COMMIT;
