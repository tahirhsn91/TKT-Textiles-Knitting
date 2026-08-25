import { db } from '../db/connection';
import path from 'path';
import fs from 'fs/promises';

/**
 * Branding Service
 * Handles white-labeling, logo management, and theme customization
 */

export interface BrandingConfig {
  id: number;
  tenant_id: number;
  company_name: string;
  company_short_name?: string;
  logo_url?: string;
  favicon_url?: string;
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  text_color: string;
  background_color: string;
  navbar_background: string;
  navbar_text_color: string;
  sidebar_background: string;
  sidebar_text_color: string;
  custom_css?: string;
  status: string;
  created_at: Date;
  updated_at: Date;
}

export interface EmailTemplate {
  id: number;
  tenant_id: number;
  template_key: string;
  template_name: string;
  subject_line: string;
  template_html: string;
  include_logo: boolean;
  include_footer: boolean;
  custom_footer_text?: string;
  status: string;
}

export interface ThemePreset {
  id: number;
  tenant_id: number;
  preset_name: string;
  preset_key: string;
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  is_default: boolean;
}

class BrandingService {
  private uploadDir = path.join(process.cwd(), 'public', 'uploads', 'logos');

  /**
   * Get branding config for a tenant
   */
  async getBrandingConfig(tenantId: number): Promise<BrandingConfig | null> {
    return db('branding_config').where({ tenant_id: tenantId }).first();
  }

  /**
   * Update branding config for a tenant
   */
  async updateBrandingConfig(
    tenantId: number,
    config: Partial<BrandingConfig>
  ): Promise<BrandingConfig> {
    const [updated] = await db('branding_config')
      .where({ tenant_id: tenantId })
      .update({
        company_name: config.company_name || undefined,
        company_short_name: config.company_short_name || undefined,
        logo_url: config.logo_url || undefined,
        favicon_url: config.favicon_url || undefined,
        primary_color: config.primary_color || undefined,
        secondary_color: config.secondary_color || undefined,
        accent_color: config.accent_color || undefined,
        text_color: config.text_color || undefined,
        background_color: config.background_color || undefined,
        navbar_background: config.navbar_background || undefined,
        navbar_text_color: config.navbar_text_color || undefined,
        sidebar_background: config.sidebar_background || undefined,
        sidebar_text_color: config.sidebar_text_color || undefined,
        custom_css: config.custom_css || undefined,
        status: config.status || undefined,
        updated_at: new Date(),
      })
      .returning('*');

    return updated;
  }

  /**
   * Upload and set logo for tenant
   */
  async uploadLogo(
    tenantId: number,
    file: Express.Multer.File,
    logoType: string = 'primary'
  ): Promise<any> {
    try {
      // Ensure upload directory exists
      await fs.mkdir(this.uploadDir, { recursive: true });

      // Generate unique filename
      const timestamp = Date.now();
      const filename = `${tenantId}-${timestamp}-${file.originalname}`;
      const filepath = path.join(this.uploadDir, filename);

      // Save file to disk
      await fs.writeFile(filepath, file.buffer);

      // Store metadata in database
      const [logoRecord] = await db('logo_uploads')
        .insert({
          tenant_id: tenantId,
          filename: filename,
          original_filename: file.originalname,
          file_type: file.mimetype,
          file_size: file.size,
          storage_url: `/uploads/logos/${filename}`,
          storage_path: filepath,
          storage_provider: 'local',
          logo_type: logoType,
          is_active: true,
        })
        .returning('*');

      // Update branding config with new logo
      await this.updateBrandingConfig(tenantId, {
        logo_url: logoRecord.storage_url,
        logo_filename: filename,
      });

      return logoRecord;
    } catch (error) {
      console.error('Logo upload error:', error);
      throw new Error('Failed to upload logo');
    }
  }

  /**
   * Get all logos for a tenant
   */
  async getTenantLogos(tenantId: number): Promise<any[]> {
    return db('logo_uploads')
      .where({ tenant_id: tenantId })
      .orderBy('created_at', 'desc');
  }

  /**
   * Delete a logo
   */
  async deleteLogo(tenantId: number, logoId: number): Promise<void> {
    const logo = await db('logo_uploads')
      .where({ id: logoId, tenant_id: tenantId })
      .first();

    if (!logo) {
      throw new Error('Logo not found');
    }

    try {
      // Delete file from disk
      await fs.unlink(logo.storage_path);

      // Delete database record
      await db('logo_uploads').where({ id: logoId }).delete();
    } catch (error) {
      console.error('Error deleting logo:', error);
      throw new Error('Failed to delete logo');
    }
  }

  /**
   * Apply theme preset to tenant
   */
  async applyThemePreset(tenantId: number, presetKey: string): Promise<BrandingConfig> {
    const preset = await db('theme_presets')
      .where({ tenant_id: tenantId, preset_key: presetKey })
      .first();

    if (!preset) {
      throw new Error('Theme preset not found');
    }

    return this.updateBrandingConfig(tenantId, {
      primary_color: preset.primary_color,
      secondary_color: preset.secondary_color,
      accent_color: preset.accent_color,
    });
  }

  /**
   * Get all theme presets for a tenant
   */
  async getThemePresets(tenantId: number): Promise<ThemePreset[]> {
    return db('theme_presets').where({ tenant_id: tenantId }).orderBy('is_default', 'desc');
  }

  /**
   * Create custom theme preset
   */
  async createThemePreset(
    tenantId: number,
    preset: Partial<ThemePreset>
  ): Promise<ThemePreset> {
    const [created] = await db('theme_presets')
      .insert({
        tenant_id: tenantId,
        preset_name: preset.preset_name,
        preset_key: preset.preset_key,
        description: preset.description,
        primary_color: preset.primary_color,
        secondary_color: preset.secondary_color,
        accent_color: preset.accent_color,
        is_default: false,
      })
      .returning('*');

    return created;
  }

  /**
   * Get email template for a tenant
   */
  async getEmailTemplate(tenantId: number, templateKey: string): Promise<EmailTemplate | null> {
    return db('email_templates')
      .where({ tenant_id: tenantId, template_key: templateKey })
      .first();
  }

  /**
   * Get all email templates for a tenant
   */
  async getEmailTemplates(tenantId: number): Promise<EmailTemplate[]> {
    return db('email_templates').where({ tenant_id: tenantId });
  }

  /**
   * Create or update email template
   */
  async upsertEmailTemplate(
    tenantId: number,
    templateKey: string,
    template: Partial<EmailTemplate>
  ): Promise<EmailTemplate> {
    const existing = await this.getEmailTemplate(tenantId, templateKey);

    if (existing) {
      const [updated] = await db('email_templates')
        .where({ tenant_id: tenantId, template_key: templateKey })
        .update({
          template_name: template.template_name || existing.template_name,
          subject_line: template.subject_line || existing.subject_line,
          template_html: template.template_html || existing.template_html,
          include_logo: template.include_logo !== undefined ? template.include_logo : existing.include_logo,
          include_footer: template.include_footer !== undefined ? template.include_footer : existing.include_footer,
          custom_footer_text: template.custom_footer_text || existing.custom_footer_text,
          updated_at: new Date(),
        })
        .returning('*');
      return updated;
    }

    const [created] = await db('email_templates')
      .insert({
        tenant_id: tenantId,
        template_key: templateKey,
        template_name: template.template_name || templateKey,
        subject_line: template.subject_line,
        template_html: template.template_html,
        include_logo: template.include_logo !== undefined ? template.include_logo : true,
        include_footer: template.include_footer !== undefined ? template.include_footer : true,
        custom_footer_text: template.custom_footer_text,
        status: 'active',
      })
      .returning('*');

    return created;
  }

  /**
   * Generate CSS variables for theme
   */
  generateThemeCSS(config: BrandingConfig): string {
    return `
      :root {
        --color-primary: ${config.primary_color};
        --color-secondary: ${config.secondary_color};
        --color-accent: ${config.accent_color};
        --color-text: ${config.text_color};
        --color-background: ${config.background_color};
        --color-border: ${config.border_color || '#E5E7EB'};
        --color-navbar-bg: ${config.navbar_background};
        --color-navbar-text: ${config.navbar_text_color};
        --color-sidebar-bg: ${config.sidebar_background};
        --color-sidebar-text: ${config.sidebar_text_color};
        --font-family: ${config.font_family || 'Inter, sans-serif'};
        --font-size-base: ${config.font_size_base || 16}px;
        --border-radius: ${config.border_radius || 6}px;
      }
      
      ${config.custom_css || ''}
    `;
  }

  /**
   * Get complete branding package for frontend
   */
  async getBrandingPackage(tenantId: number): Promise<any> {
    const config = await this.getBrandingConfig(tenantId);
    if (!config) {
      throw new Error('Branding config not found');
    }

    const presets = await this.getThemePresets(tenantId);
    const css = this.generateThemeCSS(config);

    return {
      config,
      presets,
      css,
      colors: {
        primary: config.primary_color,
        secondary: config.secondary_color,
        accent: config.accent_color,
        text: config.text_color,
        background: config.background_color,
        navbar: config.navbar_background,
        sidebar: config.sidebar_background,
      },
    };
  }
}

export const brandingService = new BrandingService();
