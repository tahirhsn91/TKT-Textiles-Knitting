-- Migration: Add tenant_id to all tables for multi-tenancy support
-- Purpose: Enable multi-tenant SaaS architecture
-- Date: 2026-08-25

-- 1. Create tenants table
CREATE TABLE IF NOT EXISTS tenants (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  slug VARCHAR(255) NOT NULL UNIQUE,
  industry VARCHAR(100),
  country VARCHAR(100) DEFAULT 'Pakistan',
  timezone VARCHAR(50) DEFAULT 'Asia/Karachi',
  currency VARCHAR(10) DEFAULT 'PKR',
  language VARCHAR(10) DEFAULT 'ur',
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB
);

-- Seed default tenant IMMEDIATELY (before adding foreign keys)
INSERT INTO tenants (id, name, slug, industry, country, timezone, currency, language, status)
VALUES (1, 'TKT Textiles', 'tkt-textiles', 'Textile & Knitting', 'Pakistan', 'Asia/Karachi', 'PKR', 'ur', 'active')
ON CONFLICT (id) DO NOTHING;

-- 2. Add tenant_id to app_user
ALTER TABLE app_user ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE app_user ADD CONSTRAINT fk_app_user_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_app_user_tenant_id ON app_user(tenant_id);

-- 3. Add tenant_id to role
ALTER TABLE role ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE role ADD CONSTRAINT fk_role_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_role_tenant_id ON role(tenant_id);

-- 4. Add tenant_id to party_master (customers/suppliers)
ALTER TABLE party_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE party_master ADD CONSTRAINT fk_party_master_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_party_master_tenant_id ON party_master(tenant_id);

-- 5. Add tenant_id to company_info_master
ALTER TABLE company_info_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE company_info_master ADD CONSTRAINT fk_company_info_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_company_info_tenant_id ON company_info_master(tenant_id);

-- 6. Add tenant_id to product-related tables
ALTER TABLE yarn_type_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_type_master ADD CONSTRAINT fk_yarn_type_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_yarn_type_tenant_id ON yarn_type_master(tenant_id);

ALTER TABLE yarn_brand_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_brand_master ADD CONSTRAINT fk_yarn_brand_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_yarn_brand_tenant_id ON yarn_brand_master(tenant_id);

ALTER TABLE yarn_count_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_count_master ADD CONSTRAINT fk_yarn_count_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_yarn_count_tenant_id ON yarn_count_master(tenant_id);

ALTER TABLE fabric_type_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE fabric_type_master ADD CONSTRAINT fk_fabric_type_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_fabric_type_tenant_id ON fabric_type_master(tenant_id);

-- 7. Add tenant_id to order/job tables
ALTER TABLE job_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE job_master ADD CONSTRAINT fk_job_master_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_job_master_tenant_id ON job_master(tenant_id);

-- 8. Add tenant_id to transaction tables
ALTER TABLE transaction_header ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE transaction_header ADD CONSTRAINT fk_transaction_header_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_transaction_header_tenant_id ON transaction_header(tenant_id);

ALTER TABLE transaction_detail ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE transaction_detail ADD CONSTRAINT fk_transaction_detail_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_transaction_detail_tenant_id ON transaction_detail(tenant_id);

ALTER TABLE transaction_type_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE transaction_type_master ADD CONSTRAINT fk_transaction_type_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_transaction_type_tenant_id ON transaction_type_master(tenant_id);

-- 9. Add tenant_id to invoice tables
ALTER TABLE invoice ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE invoice ADD CONSTRAINT fk_invoice_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_invoice_tenant_id ON invoice(tenant_id);

ALTER TABLE invoice_item ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE invoice_item ADD CONSTRAINT fk_invoice_item_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_invoice_item_tenant_id ON invoice_item(tenant_id);

ALTER TABLE invoice_payment ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE invoice_payment ADD CONSTRAINT fk_invoice_payment_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_invoice_payment_tenant_id ON invoice_payment(tenant_id);

ALTER TABLE invoice_transaction ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE invoice_transaction ADD CONSTRAINT fk_invoice_transaction_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_invoice_transaction_tenant_id ON invoice_transaction(tenant_id);

-- 10. Add tenant_id to daily operation tables
ALTER TABLE daily_production_header ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE daily_production_header ADD CONSTRAINT fk_daily_prod_header_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_daily_prod_header_tenant_id ON daily_production_header(tenant_id);

ALTER TABLE daily_production_detail ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE daily_production_detail ADD CONSTRAINT fk_daily_prod_detail_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_daily_prod_detail_tenant_id ON daily_production_detail(tenant_id);

ALTER TABLE daily_delivery ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE daily_delivery ADD CONSTRAINT fk_daily_delivery_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_daily_delivery_tenant_id ON daily_delivery(tenant_id);

-- 11. Add tenant_id to yarn receipt tables
ALTER TABLE yarn_receipt_header ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_receipt_header ADD CONSTRAINT fk_yarn_receipt_header_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_yarn_receipt_header_tenant_id ON yarn_receipt_header(tenant_id);

ALTER TABLE yarn_receipt_detail ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE yarn_receipt_detail ADD CONSTRAINT fk_yarn_receipt_detail_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_yarn_receipt_detail_tenant_id ON yarn_receipt_detail(tenant_id);

-- 12. Add tenant_id to maintenance tables
ALTER TABLE machine_maintenance ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE machine_maintenance ADD CONSTRAINT fk_machine_maint_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_machine_maint_tenant_id ON machine_maintenance(tenant_id);

ALTER TABLE factory_maintenance ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE factory_maintenance ADD CONSTRAINT fk_factory_maint_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_factory_maint_tenant_id ON factory_maintenance(tenant_id);

ALTER TABLE machine_history ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE machine_history ADD CONSTRAINT fk_machine_history_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_machine_history_tenant_id ON machine_history(tenant_id);

-- 13. Add tenant_id to configuration tables
ALTER TABLE configuration ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE configuration ADD CONSTRAINT fk_configuration_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_configuration_tenant_id ON configuration(tenant_id);

-- 14. Add tenant_id to other tables
ALTER TABLE uom_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE uom_master ADD CONSTRAINT fk_uom_master_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_uom_master_tenant_id ON uom_master(tenant_id);

ALTER TABLE machine_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE machine_master ADD CONSTRAINT fk_machine_master_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_machine_master_tenant_id ON machine_master(tenant_id);

ALTER TABLE department_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE department_master ADD CONSTRAINT fk_department_master_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_department_master_tenant_id ON department_master(tenant_id);

ALTER TABLE location_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE location_master ADD CONSTRAINT fk_location_master_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_location_master_tenant_id ON location_master(tenant_id);

ALTER TABLE employee_master ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE employee_master ADD CONSTRAINT fk_employee_master_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_employee_master_tenant_id ON employee_master(tenant_id);

ALTER TABLE attendance ADD COLUMN IF NOT EXISTS tenant_id INTEGER NOT NULL DEFAULT 1;
ALTER TABLE attendance ADD CONSTRAINT fk_attendance_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_attendance_tenant_id ON attendance(tenant_id);

-- Add composite unique indexes to prevent duplicates within a tenant
CREATE UNIQUE INDEX IF NOT EXISTS idx_yarn_type_tenant_name ON yarn_type_master(tenant_id, name);
CREATE UNIQUE INDEX IF NOT EXISTS idx_yarn_brand_tenant_name ON yarn_brand_master(tenant_id, name);
CREATE UNIQUE INDEX IF NOT EXISTS idx_fabric_type_tenant_name ON fabric_type_master(tenant_id, name);

-- Note: party_master and machine_master column names may vary; verify after migration

COMMIT;
