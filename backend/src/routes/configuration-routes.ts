import express, { Router } from 'express';
import { TenantRequest, requireTenant } from '../middleware/tenant-context';
import { configurationService } from '../services/configuration-service';

const router: Router = express.Router();

/**
 * GET /api/v1/configuration/settings
 * Get tenant settings
 */
router.get('/settings', requireTenant, async (req: TenantRequest, res) => {
  try {
    const settings = await configurationService.getTenantSettings(req.tenantId!);

    if (!settings) {
      return res.status(404).json({ error: 'Tenant settings not found' });
    }

    res.json(settings);
  } catch (error) {
    console.error('Error fetching tenant settings:', error);
    res.status(500).json({ error: 'Failed to fetch tenant settings' });
  }
});

/**
 * PUT /api/v1/configuration/settings
 * Update tenant settings
 */
router.put('/settings', requireTenant, async (req: TenantRequest, res) => {
  try {
    const settings = await configurationService.updateTenantSettings(req.tenantId!, req.body);

    res.json({
      message: 'Settings updated successfully',
      data: settings,
    });
  } catch (error) {
    console.error('Error updating tenant settings:', error);
    res.status(500).json({ error: 'Failed to update tenant settings' });
  }
});

/**
 * GET /api/v1/configuration/features
 * Get all feature flags for tenant
 */
router.get('/features', requireTenant, async (req: TenantRequest, res) => {
  try {
    const flags = await configurationService.getFeatureFlags(req.tenantId!);

    res.json({
      total: flags.length,
      enabled: flags.filter((f) => f.is_enabled).length,
      features: flags,
    });
  } catch (error) {
    console.error('Error fetching feature flags:', error);
    res.status(500).json({ error: 'Failed to fetch feature flags' });
  }
});

/**
 * GET /api/v1/configuration/features/:featureKey
 * Get specific feature flag
 */
router.get('/features/:featureKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const feature = await configurationService.getFeatureFlag(req.tenantId!, req.params.featureKey);

    if (!feature) {
      return res.status(404).json({ error: 'Feature not found' });
    }

    res.json(feature);
  } catch (error) {
    console.error('Error fetching feature flag:', error);
    res.status(500).json({ error: 'Failed to fetch feature flag' });
  }
});

/**
 * PUT /api/v1/configuration/features/:featureKey
 * Enable/disable feature flag
 */
router.put('/features/:featureKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const { is_enabled, change_reason } = req.body;

    if (typeof is_enabled !== 'boolean') {
      return res.status(400).json({ error: 'is_enabled must be a boolean' });
    }

    const updated = await configurationService.updateFeatureFlag(
      req.tenantId!,
      req.params.featureKey,
      is_enabled,
      change_reason
    );

    res.json({
      message: `Feature ${is_enabled ? 'enabled' : 'disabled'} successfully`,
      data: updated,
    });
  } catch (error) {
    console.error('Error updating feature flag:', error);
    res.status(500).json({ error: 'Failed to update feature flag' });
  }
});

/**
 * GET /api/v1/configuration/integrations
 * Get all integration settings
 */
router.get('/integrations', requireTenant, async (req: TenantRequest, res) => {
  try {
    const integrations = await configurationService.getIntegrationSettings(req.tenantId!);

    res.json({
      total: integrations.length,
      configured: integrations.filter((i) => i.is_configured).length,
      enabled: integrations.filter((i) => i.is_enabled).length,
      integrations,
    });
  } catch (error) {
    console.error('Error fetching integrations:', error);
    res.status(500).json({ error: 'Failed to fetch integrations' });
  }
});

/**
 * GET /api/v1/configuration/integrations/:integrationKey
 * Get specific integration settings
 */
router.get('/integrations/:integrationKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const integration = await configurationService.getIntegrationSetting(
      req.tenantId!,
      req.params.integrationKey
    );

    if (!integration) {
      return res.status(404).json({ error: 'Integration not found' });
    }

    res.json(integration);
  } catch (error) {
    console.error('Error fetching integration:', error);
    res.status(500).json({ error: 'Failed to fetch integration' });
  }
});

/**
 * PUT /api/v1/configuration/integrations/:integrationKey
 * Update integration settings
 */
router.put('/integrations/:integrationKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const updated = await configurationService.updateIntegrationSetting(
      req.tenantId!,
      req.params.integrationKey,
      req.body
    );

    res.json({
      message: 'Integration settings updated successfully',
      data: updated,
    });
  } catch (error) {
    console.error('Error updating integration:', error);
    res.status(500).json({ error: 'Failed to update integration' });
  }
});

/**
 * GET /api/v1/configuration/workflows
 * Get workflow settings
 */
router.get('/workflows', requireTenant, async (req: TenantRequest, res) => {
  try {
    const workflows = await configurationService.getWorkflowSettings(req.tenantId!);

    res.json({
      total: workflows.length,
      workflows,
    });
  } catch (error) {
    console.error('Error fetching workflows:', error);
    res.status(500).json({ error: 'Failed to fetch workflows' });
  }
});

/**
 * GET /api/v1/configuration/workflows/:workflowKey
 * Get specific workflow settings
 */
router.get('/workflows/:workflowKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const workflows = await configurationService.getWorkflowSettings(
      req.tenantId!,
      req.params.workflowKey
    );

    if (workflows.length === 0) {
      return res.status(404).json({ error: 'Workflow not found' });
    }

    res.json(workflows[0]);
  } catch (error) {
    console.error('Error fetching workflow:', error);
    res.status(500).json({ error: 'Failed to fetch workflow' });
  }
});

/**
 * PUT /api/v1/configuration/workflows/:workflowKey
 * Update workflow settings
 */
router.put('/workflows/:workflowKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const updated = await configurationService.updateWorkflowSettings(
      req.tenantId!,
      req.params.workflowKey,
      req.body
    );

    res.json({
      message: 'Workflow settings updated successfully',
      data: updated,
    });
  } catch (error) {
    console.error('Error updating workflow:', error);
    res.status(500).json({ error: 'Failed to update workflow' });
  }
});

/**
 * GET /api/v1/configuration/audit
 * Get configuration audit trail
 */
router.get('/audit', requireTenant, async (req: TenantRequest, res) => {
  try {
    const limit = parseInt(req.query.limit as string) || 100;
    const offset = parseInt(req.query.offset as string) || 0;
    const entityType = req.query.entity_type as string;

    const audit = await configurationService.getConfigurationAudit(req.tenantId!, {
      limit,
      offset,
      entityType,
    });

    res.json({
      total: audit.length,
      limit,
      offset,
      audit,
    });
  } catch (error) {
    console.error('Error fetching audit trail:', error);
    res.status(500).json({ error: 'Failed to fetch audit trail' });
  }
});

/**
 * GET /api/v1/configuration/summary
 * Get configuration summary for tenant
 */
router.get('/summary', requireTenant, async (req: TenantRequest, res) => {
  try {
    const summary = await configurationService.getConfigurationSummary(req.tenantId!);

    res.json(summary);
  } catch (error) {
    console.error('Error fetching configuration summary:', error);
    res.status(500).json({ error: 'Failed to fetch configuration summary' });
  }
});

/**
 * GET /api/v1/configuration/defaults
 * Get system default settings
 */
router.get('/defaults', async (req: TenantRequest, res) => {
  try {
    const defaults = await configurationService.getSystemDefaults();

    res.json(defaults);
  } catch (error) {
    console.error('Error fetching system defaults:', error);
    res.status(500).json({ error: 'Failed to fetch system defaults' });
  }
});

export default router;
