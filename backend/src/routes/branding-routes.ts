import { Router, type IRouter } from "express";
import { eq, and } from "drizzle-orm";
import { db } from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";
import { brandingConfigTable, themePresetsTable } from "../db/schema/tenants.js";
import { requireAuth } from "../lib/auth.js";
import { imageUploader, publicAssetUrl, isUploadError } from "../lib/uploads.js";

const router: IRouter = Router();
router.use(requireAuth);

/**
 * POST /api/branding/logo — upload a tenant logo (multipart, field "logo").
 * Stores the file and writes logo_url (+ filename/storage path) so the app
 * re-themes with the new logo immediately (issue #219 1.2).
 */
router.post("/logo", (req, res) => {
  const upload = imageUploader("logo");
  upload(req, res, async (err) => {
    if (err) {
      res.status(isUploadError(err) ? 400 : 500).json({ error: err.message || "Upload failed" });
      return;
    }
    const file = (req as { file?: Express.Multer.File }).file;
    if (!file) {
      res.status(400).json({ error: "No logo file provided (field: logo)" });
      return;
    }
    const tenantId = activeTenantId(req);
    const url = publicAssetUrl(file.filename);
    await updateBrandingAsset(tenantId, {
      logoUrl: url,
      logoFilename: file.originalname,
      logoStoragePath: file.filename,
    });
    res.json({ ok: true, logo_url: url, filename: file.filename });
  });
});

/**
 * POST /api/branding/favicon — upload a tenant favicon (multipart, field "favicon").
 */
router.post("/favicon", (req, res) => {
  const upload = imageUploader("favicon");
  upload(req, res, async (err) => {
    if (err) {
      res.status(isUploadError(err) ? 400 : 500).json({ error: err.message || "Upload failed" });
      return;
    }
    const file = (req as { file?: Express.Multer.File }).file;
    if (!file) {
      res.status(400).json({ error: "No favicon file provided (field: favicon)" });
      return;
    }
    const tenantId = activeTenantId(req);
    const url = publicAssetUrl(file.filename);
    await updateBrandingAsset(tenantId, { faviconUrl: url });
    res.json({ ok: true, favicon_url: url, filename: file.filename });
  });
});

/**
 * Build a CSS-variable string from a branding config so the frontend can
 * apply tenant theming without hand-mapping every field.
 */
function buildCssVariables(c: typeof brandingConfigTable.$inferSelect): string {
  const v: Record<string, string> = {
    "--brand-primary": c.primaryColor ?? "#1F2937",
    "--brand-secondary": c.secondaryColor ?? "#3B82F6",
    "--brand-accent": c.accentColor ?? "#F59E0B",
    "--brand-text": c.textColor ?? "#111827",
    "--brand-background": c.backgroundColor ?? "#FFFFFF",
    "--brand-navbar-bg": c.navbarBackground ?? "#1F2937",
    "--brand-navbar-text": c.navbarTextColor ?? "#FFFFFF",
    "--brand-sidebar-bg": c.sidebarBackground ?? "#F9FAFB",
    "--brand-sidebar-text": c.sidebarTextColor ?? "#111827",
    "--brand-accent-hover": c.accentHoverColor ?? c.accentColor ?? "#F59E0B",
    "--brand-success": c.successColor ?? "#10B981",
    "--brand-warning": c.warningColor ?? "#F59E0B",
    "--brand-error": c.errorColor ?? "#EF4444",
    "--brand-info": c.infoColor ?? "#3B82F6",
    "--brand-font": c.fontFamily ?? "Inter, sans-serif",
    "--brand-font-size": c.fontSizeBase ? `${c.fontSizeBase}px` : "16px",
    "--brand-radius": c.borderRadius ? `${c.borderRadius}px` : "6px",
    "--brand-button-style": c.buttonStyle ?? "rounded",
  };
  return `:root {\n${Object.entries(v).map(([k, val]) => `  ${k}: ${val};`).join("\n")}\n}`;
}

/**
 * GET /api/branding/package — the active tenant's branding (config + presets +
 * composed CSS variables). Tenant-scoped (runs after resolveTenant).
 */
router.get("/package", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);

  const [config] = await db
    .select()
    .from(brandingConfigTable)
    .where(eq(brandingConfigTable.tenantId, tenantId))
    .limit(1);
  if (!config) {
    res.status(404).json({ error: "Branding not configured for this tenant" });
    return;
  }

  const presets = await db
    .select()
    .from(themePresetsTable)
    .where(eq(themePresetsTable.tenantId, tenantId))
    .orderBy(themePresetsTable.id);

  const colors = {
    primary: config.primaryColor ?? "#1F2937",
    secondary: config.secondaryColor ?? "#3B82F6",
    accent: config.accentColor ?? "#F59E0B",
    text: config.textColor ?? "#111827",
    background: config.backgroundColor ?? "#FFFFFF",
    navbar: config.navbarBackground ?? "#1F2937",
    sidebar: config.sidebarBackground ?? "#F9FAFB",
  };

  res.json({
    config: {
      id: config.id,
      tenant_id: config.tenantId,
      company_name: config.companyName,
      company_short_name: config.companyShortName,
      logo_url: config.logoUrl,
      favicon_url: config.faviconUrl,
      logo_filename: config.logoFilename,
      logo_storage_path: config.logoStoragePath,
      primary_color: config.primaryColor,
      secondary_color: config.secondaryColor,
      accent_color: config.accentColor,
      text_color: config.textColor,
      background_color: config.backgroundColor,
      navbar_background: config.navbarBackground,
      navbar_text_color: config.navbarTextColor,
      sidebar_background: config.sidebarBackground,
      sidebar_text_color: config.sidebarTextColor,
      font_family: config.fontFamily,
      font_size_base: config.fontSizeBase,
      border_radius: config.borderRadius,
      button_style: config.buttonStyle,
    },
    presets: presets.map((p) => ({
      id: p.id,
      preset_name: p.presetName,
      preset_key: p.presetKey,
      description: p.description,
      primary_color: p.primaryColor,
      secondary_color: p.secondaryColor,
      accent_color: p.accentColor,
      text_color: p.textColor,
      background_color: p.backgroundColor,
      navbar_color: p.navbarColor,
      navbar_text_color: p.navbarTextColor,
      sidebar_color: p.sidebarColor,
      sidebar_text_color: p.sidebarTextColor,
      accent_hover_color: p.accentHoverColor,
      is_default: p.isDefault ?? false,
    })),
    css: buildCssVariables(config),
    colors,
  });
});

/**
 * PUT /api/branding/config — update the active tenant's branding config.
 * Accepts a partial payload; only the provided fields are updated.
 */
router.put("/config", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const body = (req.body ?? {}) as Record<string, unknown>;

  // Map wire field → schema column.
  const FIELD_MAP: Record<string, string> = {
    company_name: "companyName",
    company_short_name: "companyShortName",
    logo_url: "logoUrl",
    favicon_url: "faviconUrl",
    primary_color: "primaryColor",
    secondary_color: "secondaryColor",
    accent_color: "accentColor",
    text_color: "textColor",
    background_color: "backgroundColor",
    navbar_background: "navbarBackground",
    navbar_text_color: "navbarTextColor",
    sidebar_background: "sidebarBackground",
    sidebar_text_color: "sidebarTextColor",
    accent_hover_color: "accentHoverColor",
    font_family: "fontFamily",
    button_style: "buttonStyle",
  };

  const patch: Record<string, unknown> = {};
  for (const [wire, col] of Object.entries(FIELD_MAP)) {
    if (body[wire] !== undefined) patch[col] = body[wire];
  }

  // Ensure a branding row exists for this tenant (auto-provision if missing).
  const [existing] = await db
    .select({ id: brandingConfigTable.id })
    .from(brandingConfigTable)
    .where(eq(brandingConfigTable.tenantId, tenantId))
    .limit(1);
  if (!existing) {
    await db.insert(brandingConfigTable).values({
      tenantId,
      companyName: (body.company_name as string) ?? "New Tenant",
      ...patch,
    } as never);
  } else {
    await db
      .update(brandingConfigTable)
      .set({ ...patch, updatedAt: new Date() } as never)
      .where(eq(brandingConfigTable.id, existing.id));
  }

  res.json({ ok: true });
});

/**
 * POST /api/branding/themes/apply/:key — apply a tenant's theme preset colors
 * to its branding config (issue #219 1.2). Updates the color fields from the
 * selected preset so the UI re-themes.
 */
router.post("/themes/apply/:key", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const key = String(req.params.key);
  const [preset] = await db
    .select()
    .from(themePresetsTable)
    .where(and(eq(themePresetsTable.tenantId, tenantId), eq(themePresetsTable.presetKey, key)))
    .limit(1);
  if (!preset) {
    res.status(404).json({ error: "Theme preset not found" });
    return;
  }
  // Map every preset colour field to the branding config column so a theme
  // apply re-colours the whole app (actions, text, page, navbar + sidebar).
  const patch = JSON.parse(JSON.stringify({
    primaryColor: preset.primaryColor ?? undefined,
    secondaryColor: preset.secondaryColor ?? undefined,
    accentColor: preset.accentColor ?? undefined,
    textColor: preset.textColor ?? undefined,
    backgroundColor: preset.backgroundColor ?? undefined,
    navbarBackground: preset.navbarColor ?? undefined,
    navbarTextColor: preset.navbarTextColor ?? undefined,
    sidebarBackground: preset.sidebarColor ?? undefined,
    sidebarTextColor: preset.sidebarTextColor ?? undefined,
    accentHoverColor: preset.accentHoverColor ?? undefined,
  }));
  const [existing] = await db
    .select({ id: brandingConfigTable.id })
    .from(brandingConfigTable)
    .where(eq(brandingConfigTable.tenantId, tenantId))
    .limit(1);
  if (!existing) {
    res.status(404).json({ error: "Branding not configured for this tenant" });
    return;
  }
  // Only apply keys with values.
  const apply: Record<string, unknown> = { updatedAt: new Date() };
  for (const [k, v] of Object.entries(patch)) {
    if (v !== undefined) apply[k] = v;
  }
  await db.update(brandingConfigTable).set(apply as never).where(eq(brandingConfigTable.id, existing.id));
  res.json({ ok: true });
});

/** Update logo/favicon asset fields on the tenant's branding config. */
async function updateBrandingAsset(
  tenantId: number,
  fields: { logoUrl?: string; logoFilename?: string; logoStoragePath?: string; faviconUrl?: string },
): Promise<void> {
  const [existing] = await db
    .select({ id: brandingConfigTable.id })
    .from(brandingConfigTable)
    .where(eq(brandingConfigTable.tenantId, tenantId))
    .limit(1);
  const patch: Record<string, unknown> = { updatedAt: new Date() };
  if (fields.logoUrl !== undefined) patch.logoUrl = fields.logoUrl;
  if (fields.logoFilename !== undefined) patch.logoFilename = fields.logoFilename;
  if (fields.logoStoragePath !== undefined) patch.logoStoragePath = fields.logoStoragePath;
  if (fields.faviconUrl !== undefined) patch.faviconUrl = fields.faviconUrl;
  if (existing) {
    await db.update(brandingConfigTable).set(patch as never).where(eq(brandingConfigTable.id, existing.id));
  } else {
    await db.insert(brandingConfigTable).values({ tenantId, ...patch } as never);
  }
}

export default router;
