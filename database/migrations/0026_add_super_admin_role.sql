-- Migration: Add super-admin role for system-wide administration
-- Purpose: Enable super-admins to manage all tenants, create new tenants, switch between them
-- Date: 2026-08-25

-- 1. Add super_admin role to role table
INSERT INTO role (name, is_admin, tenant_id, created_at)
VALUES (
  'super-admin',
  TRUE,
  1,
  CURRENT_TIMESTAMP
)
ON CONFLICT (name) DO NOTHING;

-- 3. Create tenant_admin_assignments table to track which admin manages which tenants
CREATE TABLE IF NOT EXISTS tenant_admin_assignments (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  admin_user_id INTEGER NOT NULL,
  assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  assigned_by INTEGER,
  role VARCHAR(50) DEFAULT 'super-admin',
  
  CONSTRAINT fk_tenant_admin_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE,
  CONSTRAINT fk_tenant_admin_user FOREIGN KEY (admin_user_id) REFERENCES app_user(id) ON DELETE CASCADE,
  CONSTRAINT fk_tenant_admin_assignedby FOREIGN KEY (assigned_by) REFERENCES app_user(id) ON DELETE SET NULL,
  CONSTRAINT uq_tenant_admin UNIQUE(tenant_id, admin_user_id)
);

CREATE INDEX IF NOT EXISTS idx_tenant_admin_assignments_tenant ON tenant_admin_assignments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_admin_assignments_admin ON tenant_admin_assignments(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_admin_assignments_created ON tenant_admin_assignments(assigned_at DESC);

COMMIT;
