import { db } from '../db/connection';
import { tenantService } from './tenant-service';
import { brandingService } from './branding-service';
import { configurationService } from './configuration-service';

/**
 * Admin Service
 * Handles super-admin operations: tenant management, creation, configuration
 */

export interface TenantCreationInput {
  name: string;
  slug: string;
  industry: string;
  country?: string;
  timezone: string;
  currency: string;
  language: string;
}

class AdminService {
  /**
   * Get all tenants (paginated)
   */
  async getAllTenants(options: { limit?: number; offset?: number } = {}): Promise<any[]> {
    const limit = options.limit || 100;
    const offset = options.offset || 0;

    return db('tenants')
      .select('*')
      .orderBy('created_at', 'desc')
      .limit(limit)
      .offset(offset);
  }

  /**
   * Get tenant count
   */
  async getTenantCount(): Promise<number> {
    const result = await db('tenants').count('* as count').first();
    return result?.count || 0;
  }

  /**
   * Get tenant with all related configs
   */
  async getTenantDetails(tenantId: number): Promise<any> {
    const tenant = await db('tenants').where({ id: tenantId }).first();

    if (!tenant) {
      throw new Error('Tenant not found');
    }

    // Get related configs
    const settings = await configurationService.getTenantSettings(tenantId);
    const branding = await brandingService.getBrandingConfig(tenantId);
    const admins = await this.getTenantAdmins(tenantId);
    const userCount = await db('app_user').where({ tenant_id: tenantId }).count('* as count').first();

    return {
      ...tenant,
      settings,
      branding,
      admins,
      user_count: userCount?.count || 0,
    };
  }

  /**
   * Create new tenant with auto-seeding
   */
  async createTenant(input: TenantCreationInput, createdByAdminId: number): Promise<any> {
    try {
      // 1. Create tenant
      const [tenant] = await db('tenants')
        .insert({
          name: input.name,
          slug: input.slug,
          industry: input.industry,
          country: input.country || 'Pakistan',
          timezone: input.timezone,
          currency: input.currency,
          language: input.language,
          status: 'active',
        })
        .returning('*');

      // 2. Auto-seed branding config
      await db('branding_config')
        .insert({
          tenant_id: tenant.id,
          company_name: input.name,
          company_short_name: input.slug.substring(0, 10).toUpperCase(),
          primary_color: '#1F2937',
          secondary_color: '#3B82F6',
          accent_color: '#F59E0B',
          text_color: '#111827',
          background_color: '#FFFFFF',
          navbar_background: '#1F2937',
          navbar_text_color: '#FFFFFF',
          sidebar_background: '#F9FAFB',
          sidebar_text_color: '#111827',
          status: 'active',
        })
        .returning('*');

      // 3. Auto-seed tenant settings
      await db('tenant_settings')
        .insert({
          tenant_id: tenant.id,
          company_registration_number: `${input.slug.toUpperCase()}-001`,
          timezone: input.timezone,
          currency: input.currency,
          language: input.language,
          tax_enabled: true,
          default_tax_rate: 17.00,
          invoice_prefix: 'INV',
          invoice_start_number: 1001,
          email_from_name: input.name,
          email_from_address: `noreply@${input.slug}.com`,
          send_invoice_notifications: true,
          send_order_notifications: true,
          send_payment_notifications: true,
          send_production_alerts: true,
        })
        .returning('*');

      // 4. Auto-seed feature flags
      const featureFlags = [
        { feature_key: 'invoicing', feature_name: 'Invoicing Module', category: 'core', is_enabled: true },
        { feature_key: 'user_management', feature_name: 'User Management', category: 'core', is_enabled: true },
        { feature_key: 'role_based_access', feature_name: 'Role-Based Access Control', category: 'core', is_enabled: true },
        { feature_key: 'analytics', feature_name: 'Analytics Dashboard', category: 'core', is_enabled: true },
        { feature_key: 'api_access', feature_name: 'API Access', category: 'enterprise', is_enabled: false },
        { feature_key: 'advanced_reporting', feature_name: 'Advanced Reporting', category: 'enterprise', is_enabled: false },
        { feature_key: 'multi_warehouse', feature_name: 'Multi-Warehouse', category: 'enterprise', is_enabled: false },
        { feature_key: 'automated_workflows', feature_name: 'Automated Workflows', category: 'enterprise', is_enabled: false },
        { feature_key: 'audit_logs', feature_name: 'Audit Logs', category: 'security', is_enabled: true },
        { feature_key: 'two_factor_auth', feature_name: '2FA Authentication', category: 'security', is_enabled: true },
      ];

      for (const flag of featureFlags) {
        await db('feature_flags').insert({
          tenant_id: tenant.id,
          ...flag,
        });
      }

      // 5. Auto-seed theme presets
      const presets = [
        { preset_name: 'Classic Blue', preset_key: 'classic-blue', primary_color: '#1F2937', secondary_color: '#3B82F6', accent_color: '#F59E0B', is_default: true },
        { preset_name: 'Modern Dark', preset_key: 'modern-dark', primary_color: '#0F172A', secondary_color: '#1E293B', accent_color: '#64748B', is_default: false },
        { preset_name: 'Professional', preset_key: 'professional', primary_color: '#003366', secondary_color: '#0066CC', accent_color: '#FF9900', is_default: false },
        { preset_name: 'Minimal Green', preset_key: 'minimal-green', primary_color: '#065F46', secondary_color: '#10B981', accent_color: '#34D399', is_default: false },
      ];

      for (const preset of presets) {
        await db('theme_presets').insert({
          tenant_id: tenant.id,
          ...preset,
        });
      }

      // 6. Auto-seed session settings
      await db('session_settings')
        .insert({
          tenant_id: tenant.id,
          session_timeout_minutes: 30,
          remember_me_enabled: true,
          remember_me_duration_days: 30,
          max_concurrent_sessions: 5,
          force_password_change_days: 90,
          two_factor_required_for_admins: true,
          two_factor_optional_for_users: false,
          device_management_enabled: true,
          max_devices_per_user: 5,
        })
        .returning('*');

      // 7. Auto-seed OAuth providers
      const providers = [
        { provider_name: 'google', provider_type: 'oauth2', is_enabled: false, is_configured: false },
        { provider_name: 'microsoft', provider_type: 'oauth2', is_enabled: false, is_configured: false },
        { provider_name: 'github', provider_type: 'oauth2', is_enabled: false, is_configured: false },
      ];

      for (const provider of providers) {
        await db('oauth_providers').insert({
          tenant_id: tenant.id,
          ...provider,
        });
      }

      // 8. Record admin assignment
      await db('tenant_admin_assignments').insert({
        tenant_id: tenant.id,
        admin_user_id: createdByAdminId,
        assigned_by: createdByAdminId,
        role: 'super-admin',
      });

      return {
        ...tenant,
        message: 'Tenant created successfully with default configurations',
      };
    } catch (error) {
      console.error('Error creating tenant:', error);
      throw new Error('Failed to create tenant');
    }
  }

  /**
   * Update tenant
   */
  async updateTenant(tenantId: number, updates: any): Promise<any> {
    const [updated] = await db('tenants')
      .where({ id: tenantId })
      .update({
        ...updates,
        updated_at: new Date(),
      })
      .returning('*');

    return updated;
  }

  /**
   * Update tenant status (active, suspended, inactive)
   */
  async updateTenantStatus(tenantId: number, status: 'active' | 'suspended' | 'inactive'): Promise<any> {
    return this.updateTenant(tenantId, { status });
  }

  /**
   * Get tenant admins
   */
  async getTenantAdmins(tenantId: number): Promise<any[]> {
    return db('tenant_admin_assignments')
      .join('app_user', 'tenant_admin_assignments.admin_user_id', '=', 'app_user.id')
      .where('tenant_admin_assignments.tenant_id', tenantId)
      .select('app_user.id', 'app_user.email', 'app_user.firstname', 'tenant_admin_assignments.assigned_at');
  }

  /**
   * Assign admin to tenant
   */
  async assignAdminToTenant(tenantId: number, adminUserId: number, assignedByAdminId: number): Promise<any> {
    const [assignment] = await db('tenant_admin_assignments')
      .insert({
        tenant_id: tenantId,
        admin_user_id: adminUserId,
        assigned_by: assignedByAdminId,
        role: 'super-admin',
      })
      .onConflict(['tenant_id', 'admin_user_id'])
      .merge()
      .returning('*');

    return assignment;
  }

  /**
   * Remove admin from tenant
   */
  async removeAdminFromTenant(tenantId: number, adminUserId: number): Promise<void> {
    await db('tenant_admin_assignments')
      .where({ tenant_id: tenantId, admin_user_id: adminUserId })
      .delete();
  }

  /**
   * Get tenants managed by admin
   */
  async getAdminTenants(adminUserId: number): Promise<any[]> {
    return db('tenants')
      .whereIn(
        'id',
        db('tenant_admin_assignments').select('tenant_id').where({ admin_user_id: adminUserId })
      )
      .orderBy('name', 'asc');
  }

  /**
   * Get tenant statistics
   */
  async getTenantStats(tenantId: number): Promise<any> {
    const userCount = await db('app_user')
      .where({ tenant_id: tenantId })
      .count('* as count')
      .first();

    const invoiceCount = await db('invoice')
      .where({ tenant_id: tenantId })
      .count('* as count')
      .first();

    const orderCount = await db('job_master')
      .where({ tenant_id: tenantId })
      .count('* as count')
      .first();

    const totalRevenue = await db('invoice')
      .where({ tenant_id: tenantId })
      .sum('total_amount as total')
      .first();

    return {
      user_count: userCount?.count || 0,
      invoice_count: invoiceCount?.count || 0,
      order_count: orderCount?.count || 0,
      total_revenue: totalRevenue?.total || 0,
    };
  }
}

export const adminService = new AdminService();
