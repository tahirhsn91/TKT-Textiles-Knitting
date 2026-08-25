-- Migration: Add authentication and authorization hardening features
-- Purpose: User invitations, session management, 2FA, SSO-readiness
-- Date: 2026-08-25

-- 1. Create user_invitations table for team member invitations
CREATE TABLE IF NOT EXISTS user_invitations (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  invited_by INTEGER NOT NULL,
  email VARCHAR(255) NOT NULL,
  role_id INTEGER,
  role_name VARCHAR(100),
  invitation_code VARCHAR(255) NOT NULL UNIQUE,
  invitation_token VARCHAR(500) NOT NULL UNIQUE,
  status VARCHAR(50) DEFAULT 'pending',
  accepted_at TIMESTAMP,
  expired_at TIMESTAMP,
  accepted_by_user_id INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_invitations_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_invitations_inviter FOREIGN KEY (invited_by) REFERENCES app_user(id) ON DELETE SET NULL,
  CONSTRAINT fk_user_invitations_acceptor FOREIGN KEY (accepted_by_user_id) REFERENCES app_user(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_user_invitations_tenant ON user_invitations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_invitations_email ON user_invitations(tenant_id, email);
CREATE INDEX IF NOT EXISTS idx_user_invitations_token ON user_invitations(invitation_token);
CREATE INDEX IF NOT EXISTS idx_user_invitations_status ON user_invitations(status, expired_at);

-- 2. Create user_sessions table for session management
CREATE TABLE IF NOT EXISTS user_sessions (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  session_token VARCHAR(500) NOT NULL UNIQUE,
  refresh_token VARCHAR(500),
  
  -- Session metadata
  device_name VARCHAR(255),
  device_type VARCHAR(50),
  ip_address VARCHAR(45),
  user_agent TEXT,
  
  -- Session control
  is_active BOOLEAN DEFAULT TRUE,
  last_activity_at TIMESTAMP,
  expires_at TIMESTAMP,
  
  -- Security
  two_factor_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_sessions_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_user_sessions_tenant ON user_sessions(tenant_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at);

-- 3. Create two_factor_auth table for 2FA configuration
CREATE TABLE IF NOT EXISTS two_factor_auth (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  
  -- 2FA status
  is_enabled BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMP,
  
  -- TOTP (Time-based One-Time Password)
  totp_secret VARCHAR(255),
  totp_backup_codes TEXT,
  
  -- SMS 2FA
  phone_number VARCHAR(20),
  phone_verified BOOLEAN DEFAULT FALSE,
  sms_enabled BOOLEAN DEFAULT FALSE,
  
  -- Email 2FA
  email_enabled BOOLEAN DEFAULT FALSE,
  
  -- Recovery
  recovery_codes_generated_at TIMESTAMP,
  recovery_codes_used_count INTEGER DEFAULT 0,
  last_verified_at TIMESTAMP,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_2fa_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_2fa_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
  CONSTRAINT uq_2fa_user UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_2fa_tenant ON two_factor_auth(tenant_id);
CREATE INDEX IF NOT EXISTS idx_2fa_enabled ON two_factor_auth(user_id, is_enabled);

-- 4. Create login_attempts table for brute force protection
CREATE TABLE IF NOT EXISTS login_attempts (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  email VARCHAR(255) NOT NULL,
  ip_address VARCHAR(45) NOT NULL,
  
  -- Attempt details
  attempt_count INTEGER DEFAULT 1,
  status VARCHAR(50) DEFAULT 'failed',
  failure_reason VARCHAR(255),
  
  -- Lockout
  is_locked BOOLEAN DEFAULT FALSE,
  locked_until TIMESTAMP,
  lockout_reason VARCHAR(255),
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_login_attempts_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_login_attempts_email ON login_attempts(tenant_id, email);
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip ON login_attempts(ip_address);
CREATE INDEX IF NOT EXISTS idx_login_attempts_locked ON login_attempts(email, is_locked, locked_until);

-- 5. Create password_reset_tokens table for secure password resets
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  reset_token VARCHAR(500) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL,
  
  -- Reset control
  is_used BOOLEAN DEFAULT FALSE,
  used_at TIMESTAMP,
  expires_at TIMESTAMP,
  
  -- Security
  ip_address VARCHAR(45),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_password_reset_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_password_reset_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_password_reset_token ON password_reset_tokens(reset_token);
CREATE INDEX IF NOT EXISTS idx_password_reset_user ON password_reset_tokens(user_id, is_used);
CREATE INDEX IF NOT EXISTS idx_password_reset_expires ON password_reset_tokens(expires_at);

-- 6. Create oauth_providers table for SSO integration (future-proofing)
CREATE TABLE IF NOT EXISTS oauth_providers (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  provider_name VARCHAR(100) NOT NULL,
  provider_type VARCHAR(50),
  
  -- OAuth configuration
  client_id VARCHAR(255),
  client_secret VARCHAR(255),
  redirect_uri VARCHAR(500),
  scope VARCHAR(500),
  
  -- Status
  is_enabled BOOLEAN DEFAULT FALSE,
  is_configured BOOLEAN DEFAULT FALSE,
  
  -- Metadata
  config_json JSONB,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_oauth_providers_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT uq_oauth_provider UNIQUE(tenant_id, provider_name)
);

CREATE INDEX IF NOT EXISTS idx_oauth_providers_tenant ON oauth_providers(tenant_id, is_enabled);

-- 7. Create user_oauth_accounts table for linked OAuth accounts
CREATE TABLE IF NOT EXISTS user_oauth_accounts (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  provider_name VARCHAR(100) NOT NULL,
  provider_user_id VARCHAR(255) NOT NULL,
  access_token VARCHAR(500),
  refresh_token VARCHAR(500),
  token_expires_at TIMESTAMP,
  
  linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_oauth_accounts_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_oauth_accounts_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
  CONSTRAINT uq_oauth_account UNIQUE(tenant_id, user_id, provider_name)
);

CREATE INDEX IF NOT EXISTS idx_oauth_accounts_user ON user_oauth_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_provider ON user_oauth_accounts(tenant_id, provider_name);

-- 8. Create auth_audit table for authentication event tracking
CREATE TABLE IF NOT EXISTS auth_audit (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  user_id INTEGER,
  email VARCHAR(255),
  
  -- Event details
  event_type VARCHAR(50),
  event_description VARCHAR(500),
  status VARCHAR(50),
  
  -- Security context
  ip_address VARCHAR(45),
  user_agent TEXT,
  device_fingerprint VARCHAR(255),
  location_info VARCHAR(255),
  
  -- Risk assessment
  risk_level VARCHAR(50) DEFAULT 'low',
  suspicious_activity BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_auth_audit_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_auth_audit_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_auth_audit_tenant ON auth_audit(tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_auth_audit_user ON auth_audit(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_audit_event ON auth_audit(tenant_id, event_type);
CREATE INDEX IF NOT EXISTS idx_auth_audit_ip ON auth_audit(ip_address);

-- 9. Create session_settings table for tenant-specific session policies
CREATE TABLE IF NOT EXISTS session_settings (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL UNIQUE,
  
  -- Session policy
  session_timeout_minutes INTEGER DEFAULT 30,
  remember_me_enabled BOOLEAN DEFAULT TRUE,
  remember_me_duration_days INTEGER DEFAULT 30,
  max_concurrent_sessions INTEGER DEFAULT 5,
  
  -- Security policy
  force_password_change_days INTEGER DEFAULT 90,
  password_expiry_enabled BOOLEAN DEFAULT FALSE,
  
  -- 2FA policy
  two_factor_required_for_admins BOOLEAN DEFAULT TRUE,
  two_factor_optional_for_users BOOLEAN DEFAULT FALSE,
  
  -- Device management
  device_management_enabled BOOLEAN DEFAULT TRUE,
  max_devices_per_user INTEGER DEFAULT 5,
  
  -- IP restriction
  ip_whitelist_enabled BOOLEAN DEFAULT FALSE,
  ip_whitelist VARCHAR(1000),
  
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_session_settings_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_session_settings_tenant ON session_settings(tenant_id);

-- 10. Seed default session settings for TKT Textiles (tenant_id = 1)
INSERT INTO session_settings (
  tenant_id,
  session_timeout_minutes,
  remember_me_enabled,
  max_concurrent_sessions,
  two_factor_required_for_admins,
  device_management_enabled
)
VALUES (
  1,
  30,
  TRUE,
  5,
  TRUE,
  TRUE
)
ON CONFLICT (tenant_id) DO NOTHING;

-- 11. Seed default OAuth providers (disabled by default)
INSERT INTO oauth_providers (tenant_id, provider_name, provider_type, is_enabled, is_configured)
VALUES 
  (1, 'google', 'oauth2', FALSE, FALSE),
  (1, 'microsoft', 'oauth2', FALSE, FALSE),
  (1, 'github', 'oauth2', FALSE, FALSE)
ON CONFLICT (tenant_id, provider_name) DO NOTHING;

-- 12. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_invitations_created ON user_invitations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_sessions_created ON user_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_attempts_created ON login_attempts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_auth_audit_created ON auth_audit(created_at DESC);

COMMIT;
