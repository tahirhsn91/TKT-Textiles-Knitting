import express, { Router } from 'express';
import multer from 'multer';
import { TenantRequest, requireTenant } from '../middleware/tenant-context';
import { brandingService } from '../services/branding-service';

const router: Router = express.Router();

// Configure multer for logo uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/png', 'image/svg+xml', 'image/webp'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPEG, PNG, SVG, and WebP are allowed.'));
    }
  },
});

/**
 * GET /api/v1/branding/config
 * Get branding configuration for current tenant
 */
router.get('/config', requireTenant, async (req: TenantRequest, res) => {
  try {
    const config = await brandingService.getBrandingConfig(req.tenantId!);

    if (!config) {
      return res.status(404).json({ error: 'Branding config not found' });
    }

    res.json(config);
  } catch (error) {
    console.error('Error fetching branding config:', error);
    res.status(500).json({ error: 'Failed to fetch branding config' });
  }
});

/**
 * PUT /api/v1/branding/config
 * Update branding configuration for current tenant
 */
router.put('/config', requireTenant, async (req: TenantRequest, res) => {
  try {
    const {
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
      custom_css,
    } = req.body;

    // Validate colors (basic hex color validation)
    const colors = [
      primary_color,
      secondary_color,
      accent_color,
      text_color,
      background_color,
      navbar_background,
      navbar_text_color,
      sidebar_background,
      sidebar_text_color,
    ];

    for (const color of colors) {
      if (color && !/^#[0-9A-F]{6}$/i.test(color)) {
        return res.status(400).json({ error: 'Invalid color format. Use hex colors (e.g., #FF0000)' });
      }
    }

    const updated = await brandingService.updateBrandingConfig(req.tenantId!, {
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
      custom_css,
    });

    res.json({
      message: 'Branding config updated successfully',
      data: updated,
    });
  } catch (error) {
    console.error('Error updating branding config:', error);
    res.status(500).json({ error: 'Failed to update branding config' });
  }
});

/**
 * GET /api/v1/branding/package
 * Get complete branding package (config + CSS + presets) for frontend
 */
router.get('/package', requireTenant, async (req: TenantRequest, res) => {
  try {
    const brandingPackage = await brandingService.getBrandingPackage(req.tenantId!);
    res.json(brandingPackage);
  } catch (error) {
    console.error('Error fetching branding package:', error);
    res.status(500).json({ error: 'Failed to fetch branding package' });
  }
});

/**
 * POST /api/v1/branding/logo
 * Upload logo for current tenant
 */
router.post('/logo', requireTenant, upload.single('logo'), async (req: TenantRequest, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    const logoType = (req.body.logoType as string) || 'primary';
    const logoRecord = await brandingService.uploadLogo(req.tenantId!, req.file, logoType);

    res.json({
      message: 'Logo uploaded successfully',
      data: logoRecord,
    });
  } catch (error) {
    console.error('Error uploading logo:', error);
    res.status(500).json({ error: 'Failed to upload logo' });
  }
});

/**
 * GET /api/v1/branding/logos
 * Get all logos for current tenant
 */
router.get('/logos', requireTenant, async (req: TenantRequest, res) => {
  try {
    const logos = await brandingService.getTenantLogos(req.tenantId!);
    res.json(logos);
  } catch (error) {
    console.error('Error fetching logos:', error);
    res.status(500).json({ error: 'Failed to fetch logos' });
  }
});

/**
 * DELETE /api/v1/branding/logo/:logoId
 * Delete a logo
 */
router.delete('/logo/:logoId', requireTenant, async (req: TenantRequest, res) => {
  try {
    const logoId = parseInt(req.params.logoId);

    await brandingService.deleteLogo(req.tenantId!, logoId);

    res.json({ message: 'Logo deleted successfully' });
  } catch (error) {
    console.error('Error deleting logo:', error);
    res.status(500).json({ error: 'Failed to delete logo' });
  }
});

/**
 * GET /api/v1/branding/themes
 * Get all theme presets for current tenant
 */
router.get('/themes', requireTenant, async (req: TenantRequest, res) => {
  try {
    const presets = await brandingService.getThemePresets(req.tenantId!);
    res.json(presets);
  } catch (error) {
    console.error('Error fetching theme presets:', error);
    res.status(500).json({ error: 'Failed to fetch theme presets' });
  }
});

/**
 * POST /api/v1/branding/themes/apply/:presetKey
 * Apply a theme preset
 */
router.post('/themes/apply/:presetKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const presetKey = req.params.presetKey;
    const updated = await brandingService.applyThemePreset(req.tenantId!, presetKey);

    res.json({
      message: 'Theme preset applied successfully',
      data: updated,
    });
  } catch (error) {
    console.error('Error applying theme preset:', error);
    res.status(500).json({ error: 'Failed to apply theme preset' });
  }
});

/**
 * POST /api/v1/branding/themes
 * Create custom theme preset
 */
router.post('/themes', requireTenant, async (req: TenantRequest, res) => {
  try {
    const { preset_name, preset_key, primary_color, secondary_color, accent_color } = req.body;

    if (!preset_name || !preset_key) {
      return res.status(400).json({ error: 'preset_name and preset_key are required' });
    }

    const preset = await brandingService.createThemePreset(req.tenantId!, {
      preset_name,
      preset_key,
      primary_color,
      secondary_color,
      accent_color,
    });

    res.status(201).json({
      message: 'Theme preset created successfully',
      data: preset,
    });
  } catch (error) {
    console.error('Error creating theme preset:', error);
    res.status(500).json({ error: 'Failed to create theme preset' });
  }
});

/**
 * GET /api/v1/branding/email-templates
 * Get all email templates for current tenant
 */
router.get('/email-templates', requireTenant, async (req: TenantRequest, res) => {
  try {
    const templates = await brandingService.getEmailTemplates(req.tenantId!);
    res.json(templates);
  } catch (error) {
    console.error('Error fetching email templates:', error);
    res.status(500).json({ error: 'Failed to fetch email templates' });
  }
});

/**
 * GET /api/v1/branding/email-templates/:templateKey
 * Get specific email template
 */
router.get('/email-templates/:templateKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const templateKey = req.params.templateKey;
    const template = await brandingService.getEmailTemplate(req.tenantId!, templateKey);

    if (!template) {
      return res.status(404).json({ error: 'Email template not found' });
    }

    res.json(template);
  } catch (error) {
    console.error('Error fetching email template:', error);
    res.status(500).json({ error: 'Failed to fetch email template' });
  }
});

/**
 * POST /api/v1/branding/email-templates/:templateKey
 * Create or update email template
 */
router.post('/email-templates/:templateKey', requireTenant, async (req: TenantRequest, res) => {
  try {
    const templateKey = req.params.templateKey;
    const { template_name, subject_line, template_html, include_logo, include_footer, custom_footer_text } =
      req.body;

    const template = await brandingService.upsertEmailTemplate(req.tenantId!, templateKey, {
      template_name,
      subject_line,
      template_html,
      include_logo,
      include_footer,
      custom_footer_text,
    });

    res.json({
      message: 'Email template saved successfully',
      data: template,
    });
  } catch (error) {
    console.error('Error saving email template:', error);
    res.status(500).json({ error: 'Failed to save email template' });
  }
});

export default router;
