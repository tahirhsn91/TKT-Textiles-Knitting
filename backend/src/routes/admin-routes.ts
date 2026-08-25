import express, { Router } from 'express';
import { SuperAdminRequest, requireSuperAdmin } from '../middleware/super-admin';
import { tenantMiddleware, requireTenant, TenantRequest } from '../middleware/tenant-context';
import { adminService } from '../services/admin-service';
import jwt from 'jsonwebtoken';

const router: Router = express.Router();

// Apply tenant middleware to all admin routes
router.use(tenantMiddleware);

/**
 * GET /api/admin/tenants
 * List all tenants (super-admin only, paginated)
 */
router.get('/tenants', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const offset = parseInt(req.query.offset as string) || 0;

    const tenants = await adminService.getAllTenants({ limit, offset });
    const totalCount = await adminService.getTenantCount();

    res.json({
      total: totalCount,
      limit,
      offset,
      tenants,
    });
  } catch (error) {
    console.error('Error fetching tenants:', error);
    res.status(500).json({ error: 'Failed to fetch tenants' });
  }
});

/**
 * GET /api/admin/tenants/:tenantId
 * Get detailed tenant information (super-admin only)
 */
router.get('/tenants/:tenantId', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenantId = parseInt(req.params.tenantId);
    const tenant = await adminService.getTenantDetails(tenantId);

    res.json(tenant);
  } catch (error) {
    console.error('Error fetching tenant:', error);
    res.status(500).json({ error: 'Failed to fetch tenant' });
  }
});

/**
 * POST /api/admin/tenants
 * Create new tenant (super-admin only)
 */
router.post('/tenants', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const { name, slug, industry, country, timezone, currency, language } = req.body;

    // Validate required fields
    if (!name || !slug || !industry || !timezone || !currency || !language) {
      return res.status(400).json({
        error: 'Missing required fields: name, slug, industry, timezone, currency, language',
      });
    }

    const tenant = await adminService.createTenant(
      {
        name,
        slug,
        industry,
        country: country || 'Pakistan',
        timezone,
        currency,
        language,
      },
      req.userId!
    );

    res.status(201).json({
      message: 'Tenant created successfully',
      data: tenant,
    });
  } catch (error) {
    console.error('Error creating tenant:', error);
    res.status(500).json({ error: 'Failed to create tenant' });
  }
});

/**
 * PUT /api/admin/tenants/:tenantId
 * Update tenant (super-admin only)
 */
router.put('/tenants/:tenantId', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenantId = parseInt(req.params.tenantId);
    const { name, status, timezone, currency, language } = req.body;

    const updated = await adminService.updateTenant(tenantId, {
      name: name || undefined,
      status: status || undefined,
      timezone: timezone || undefined,
      currency: currency || undefined,
      language: language || undefined,
    });

    res.json({
      message: 'Tenant updated successfully',
      data: updated,
    });
  } catch (error) {
    console.error('Error updating tenant:', error);
    res.status(500).json({ error: 'Failed to update tenant' });
  }
});

/**
 * PUT /api/admin/tenants/:tenantId/status
 * Update tenant status (super-admin only)
 */
router.put('/tenants/:tenantId/status', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenantId = parseInt(req.params.tenantId);
    const { status } = req.body;

    if (!['active', 'suspended', 'inactive'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status. Must be: active, suspended, or inactive' });
    }

    const updated = await adminService.updateTenantStatus(tenantId, status);

    res.json({
      message: `Tenant status updated to ${status}`,
      data: updated,
    });
  } catch (error) {
    console.error('Error updating tenant status:', error);
    res.status(500).json({ error: 'Failed to update tenant status' });
  }
});

/**
 * GET /api/admin/tenants/:tenantId/stats
 * Get tenant statistics (super-admin only)
 */
router.get('/tenants/:tenantId/stats', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenantId = parseInt(req.params.tenantId);
    const stats = await adminService.getTenantStats(tenantId);

    res.json(stats);
  } catch (error) {
    console.error('Error fetching tenant stats:', error);
    res.status(500).json({ error: 'Failed to fetch tenant stats' });
  }
});

/**
 * POST /api/admin/switch-tenant/:tenantId
 * Switch tenant context (super-admin only, returns new JWT token)
 */
router.post('/switch-tenant/:tenantId', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenantId = parseInt(req.params.tenantId);

    // Verify tenant exists
    const tenant = await adminService.getTenantDetails(tenantId);
    if (!tenant) {
      return res.status(404).json({ error: 'Tenant not found' });
    }

    // Create new JWT token with new tenant context
    const newToken = jwt.sign(
      {
        userId: req.userId,
        id: req.userId,
        tenantId: tenantId,
        email: req.user?.email,
        role: 'super-admin',
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    res.json({
      message: `Switched to tenant: ${tenant.name}`,
      tenant_id: tenantId,
      tenant_name: tenant.name,
      new_token: newToken,
    });
  } catch (error) {
    console.error('Error switching tenant:', error);
    res.status(500).json({ error: 'Failed to switch tenant' });
  }
});

/**
 * GET /api/admin/my-tenants
 * Get tenants managed by current super-admin
 */
router.get('/my-tenants', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenants = await adminService.getAdminTenants(req.userId!);

    res.json({
      total: tenants.length,
      tenants: tenants.map((t) => ({
        id: t.id,
        name: t.name,
        slug: t.slug,
        status: t.status,
        created_at: t.created_at,
      })),
    });
  } catch (error) {
    console.error('Error fetching admin tenants:', error);
    res.status(500).json({ error: 'Failed to fetch tenants' });
  }
});

/**
 * GET /api/admin/tenants/:tenantId/admins
 * Get admins for a tenant (super-admin only)
 */
router.get('/tenants/:tenantId/admins', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenantId = parseInt(req.params.tenantId);
    const admins = await adminService.getTenantAdmins(tenantId);

    res.json({
      total: admins.length,
      admins,
    });
  } catch (error) {
    console.error('Error fetching tenant admins:', error);
    res.status(500).json({ error: 'Failed to fetch tenant admins' });
  }
});

/**
 * POST /api/admin/tenants/:tenantId/assign-admin
 * Assign admin to tenant (super-admin only)
 */
router.post('/tenants/:tenantId/assign-admin', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenantId = parseInt(req.params.tenantId);
    const { admin_user_id } = req.body;

    if (!admin_user_id) {
      return res.status(400).json({ error: 'admin_user_id is required' });
    }

    const assignment = await adminService.assignAdminToTenant(tenantId, admin_user_id, req.userId!);

    res.status(201).json({
      message: 'Admin assigned to tenant successfully',
      data: assignment,
    });
  } catch (error) {
    console.error('Error assigning admin:', error);
    res.status(500).json({ error: 'Failed to assign admin' });
  }
});

/**
 * DELETE /api/admin/tenants/:tenantId/admins/:adminUserId
 * Remove admin from tenant (super-admin only)
 */
router.delete('/tenants/:tenantId/admins/:adminUserId', requireSuperAdmin, async (req: SuperAdminRequest, res) => {
  try {
    const tenantId = parseInt(req.params.tenantId);
    const adminUserId = parseInt(req.params.adminUserId);

    await adminService.removeAdminFromTenant(tenantId, adminUserId);

    res.json({ message: 'Admin removed from tenant successfully' });
  } catch (error) {
    console.error('Error removing admin:', error);
    res.status(500).json({ error: 'Failed to remove admin' });
  }
});

export default router;
