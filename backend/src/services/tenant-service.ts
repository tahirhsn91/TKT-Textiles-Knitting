import { db } from '../db/connection';

/**
 * Tenant Service
 * Handles tenant management, configuration, and data isolation
 */

export interface Tenant {
  id: number;
  name: string;
  slug: string;
  industry?: string;
  country?: string;
  timezone?: string;
  currency?: string;
  language?: string;
  status: string;
  created_at?: Date;
  updated_at?: Date;
  metadata?: any;
}

export interface TenantConfig {
  tenant_id: number;
  company_name: string;
  logo_url?: string;
  primary_color?: string;
  secondary_color?: string;
  timezone: string;
  currency: string;
  language: string;
  features?: {
    invoicing?: boolean;
    analytics?: boolean;
    api_access?: boolean;
    advanced_reporting?: boolean;
  };
}

class TenantService {
  /**
   * Create a new tenant
   */
  async createTenant(data: Partial<Tenant>): Promise<Tenant> {
    const [tenant] = await db('tenants')
      .insert({
        name: data.name,
        slug: data.slug || data.name?.toLowerCase().replace(/\s+/g, '-'),
        industry: data.industry || 'Textile & Knitting',
        country: data.country || 'Pakistan',
        timezone: data.timezone || 'Asia/Karachi',
        currency: data.currency || 'PKR',
        language: data.language || 'ur',
        status: data.status || 'active',
        metadata: data.metadata || {},
      })
      .returning('*');

    return tenant;
  }

  /**
   * Get tenant by ID
   */
  async getTenantById(tenantId: number): Promise<Tenant | null> {
    return db('tenants').where({ id: tenantId }).first();
  }

  /**
   * Get tenant by slug
   */
  async getTenantBySlug(slug: string): Promise<Tenant | null> {
    return db('tenants').where({ slug }).first();
  }

  /**
   * Get tenant configuration
   */
  async getTenantConfig(tenantId: number): Promise<TenantConfig | null> {
    const tenant = await this.getTenantById(tenantId);
    if (!tenant) {
      return null;
    }

    return {
      tenant_id: tenant.id,
      company_name: tenant.name,
      timezone: tenant.timezone || 'Asia/Karachi',
      currency: tenant.currency || 'PKR',
      language: tenant.language || 'ur',
      features: {
        invoicing: true,
        analytics: true,
        api_access: false, // Default, enable per tenant
        advanced_reporting: false,
      },
    };
  }

  /**
   * Update tenant configuration
   */
  async updateTenantConfig(
    tenantId: number,
    config: Partial<TenantConfig>
  ): Promise<Tenant> {
    const [tenant] = await db('tenants')
      .where({ id: tenantId })
      .update({
        name: config.company_name || undefined,
        timezone: config.timezone || undefined,
        currency: config.currency || undefined,
        language: config.language || undefined,
        metadata: config.features || undefined,
      })
      .returning('*');

    return tenant;
  }

  /**
   * Get all users in a tenant
   */
  async getTenantUsers(tenantId: number) {
    return db('app_user')
      .where({ tenant_id: tenantId })
      .select('id', 'email', 'firstname', 'role', 'status');
  }

  /**
   * Count resources by tenant
   */
  async getTenantMetrics(tenantId: number) {
    const users = await db('app_user')
      .where({ tenant_id: tenantId })
      .count('* as count')
      .first();

    const orders = await db('job_master')
      .where({ tenant_id: tenantId })
      .count('* as count')
      .first();

    const invoices = await db('invoice')
      .where({ tenant_id: tenantId })
      .count('* as count')
      .first();

    const revenue = await db('invoice')
      .where({ tenant_id: tenantId })
      .sum('total_amount as total')
      .first();

    return {
      users: users?.count || 0,
      orders: orders?.count || 0,
      invoices: invoices?.count || 0,
      revenue: revenue?.total || 0,
    };
  }

  /**
   * Enable/disable features for tenant
   */
  async updateTenantFeatures(
    tenantId: number,
    features: Record<string, boolean>
  ): Promise<Tenant> {
    const tenant = await this.getTenantById(tenantId);
    if (!tenant) {
      throw new Error('Tenant not found');
    }

    const [updated] = await db('tenants')
      .where({ id: tenantId })
      .update({
        metadata: {
          ...tenant.metadata,
          features,
        },
      })
      .returning('*');

    return updated;
  }

  /**
   * Suspend/activate tenant
   */
  async updateTenantStatus(
    tenantId: number,
    status: 'active' | 'suspended' | 'inactive'
  ): Promise<Tenant> {
    const [tenant] = await db('tenants')
      .where({ id: tenantId })
      .update({ status })
      .returning('*');

    return tenant;
  }

  /**
   * Get tenant statistics
   */
  async getTenantStats(tenantId: number) {
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const monthlyRevenue = await db('invoice')
      .where({ tenant_id: tenantId })
      .whereRaw('created_at >= ?', [thirtyDaysAgo])
      .sum('total_amount as total')
      .first();

    const monthlyOrders = await db('job_master')
      .where({ tenant_id: tenantId })
      .whereRaw('created_at >= ?', [thirtyDaysAgo])
      .count('* as count')
      .first();

    return {
      monthly_revenue: monthlyRevenue?.total || 0,
      monthly_orders: monthlyOrders?.count || 0,
      created_at: (await this.getTenantById(tenantId))?.created_at,
    };
  }
}

export const tenantService = new TenantService();
