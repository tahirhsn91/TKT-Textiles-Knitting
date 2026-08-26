import { Router, type IRouter } from "express";
import { eq, and } from "drizzle-orm";
import { db } from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";
import { tenantSettingsTable, featureFlagsTable, brandingConfigTable } from "../db/schema/tenants.js";
import { auditLogTable } from "../db/schema/audit-log.js";
import { requireAuth } from "../lib/auth.js";

const router: IRouter = Router();
router.use(requireAuth);

// ─── Helpers ────────────────────────────────────────────────────────────────

async function ensureSettingsRow(tenantId: number) {
  const [existing] = await db
    .select({ id: tenantSettingsTable.id })
    .from(tenantSettingsTable)
    .where(eq(tenantSettingsTable.tenantId, tenantId))
    .limit(1);
  if (!existing) {
    const [row] = await db
      .insert(tenantSettingsTable)
      .values({ tenantId })
      .returning({ id: tenantSettingsTable.id });
    return row.id;
  }
  return existing.id;
}

function serializeSettings(s: typeof tenantSettingsTable.$inferSelect) {
  return {
    id: s.id,
    tenant_id: s.tenantId,
    company_registration_number: s.companyRegistrationNumber,
    company_tax_id: s.companyTaxId,
    company_bank_account: s.companyBankAccount,
    company_phone: s.companyPhone,
    company_email: s.companyEmail,
    company_website: s.companyWebsite,
    company_address: s.companyAddress,
    company_city: s.companyCity,
    company_province: s.companyProvince,
    company_postal_code: s.companyPostalCode,
    company_country: s.companyCountry ?? "Pakistan",
    business_type: s.businessType,
    industry_category: s.industryCategory,
    timezone: s.timezone ?? "Asia/Karachi",
    currency: s.currency ?? "PKR",
    language: s.language ?? "ur",
    date_format: s.dateFormat ?? "DD/MM/YYYY",
    number_format: s.numberFormat ?? "1,234.56",
    tax_enabled: s.taxEnabled ?? true,
    default_tax_rate: s.defaultTaxRate ? Number(s.defaultTaxRate) : 17,
    tax_method: s.taxMethod ?? "inclusive",
  };
}

/**
 * GET /api/configuration/settings — the active tenant's company settings.
 */
router.get("/settings", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const [settings] = await db
    .select()
    .from(tenantSettingsTable)
    .where(eq(tenantSettingsTable.tenantId, tenantId))
    .limit(1);
  if (!settings) {
    // Auto-provision an empty row? Better: return 404 if unconfigured.
    res.status(404).json({ error: "Tenant settings not configured" });
    return;
  }
  res.json(serializeSettings(settings));
});

/**
 * PUT /api/configuration/settings — update the active tenant's company settings.
 * Logs the change to the audit log.
 */
router.put("/settings", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const body = (req.body ?? {}) as Record<string, unknown>;

  const FIELD_MAP: Record<string, string> = {
    company_registration_number: "companyRegistrationNumber",
    company_tax_id: "companyTaxId",
    company_bank_account: "companyBankAccount",
    company_phone: "companyPhone",
    company_email: "companyEmail",
    company_website: "companyWebsite",
    company_address: "companyAddress",
    company_city: "companyCity",
    company_province: "companyProvince",
    company_postal_code: "companyPostalCode",
    company_country: "companyCountry",
    business_type: "businessType",
    industry_category: "industryCategory",
    timezone: "timezone",
    currency: "currency",
    language: "language",
    date_format: "dateFormat",
    number_format: "numberFormat",
    tax_enabled: "taxEnabled",
    default_tax_rate: "defaultTaxRate",
    tax_method: "taxMethod",
  };

  const patch: Record<string, unknown> = {};
  for (const [wire, col] of Object.entries(FIELD_MAP)) {
    if (body[wire] !== undefined) {
      // default_tax_rate is numeric in the DB (numeric(5,2)) stored as string.
      patch[col] = wire === "default_tax_rate" ? String(Number(body[wire])) : body[wire];
    }
  }

  const id = await ensureSettingsRow(tenantId);
  const [updated] = await db
    .update(tenantSettingsTable)
    .set({ ...patch, updatedAt: new Date().toISOString() } as never)
    .where(eq(tenantSettingsTable.id, id))
    .returning();

  await db.insert(auditLogTable).values({
    actorUserId: req.auth!.sub,
    targetTenantId: tenantId,
    action: "settings.update",
    entityType: "tenant_settings",
    entityId: tenantId,
    description: "Company settings updated",
    afterJson: patch,
  });

  res.json({ data: serializeSettings(updated) });
});

/**
 * GET /api/configuration/features — the active tenant's feature flags.
 */
router.get("/features", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const rows = await db
    .select()
    .from(featureFlagsTable)
    .where(eq(featureFlagsTable.tenantId, tenantId))
    .orderBy(featureFlagsTable.featureKey);
  res.json({
    features: rows.map((r) => ({
      id: r.id,
      feature_key: r.featureKey,
      feature_name: r.featureName,
      is_enabled: r.isEnabled ?? true,
      category: r.category,
      max_users: r.maxUsers,
    })),
  });
});

/**
 * PUT /api/configuration/features/:key — toggle a feature flag.
 */
router.put("/features/:key", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const key = String(req.params.key);
  const isEnabled = Boolean((req.body ?? {}).is_enabled);

  const [existing] = await db
    .select()
    .from(featureFlagsTable)
    .where(eq(featureFlagsTable.tenantId, tenantId))
    .limit(1);
  void existing;

  const [updated] = await db
    .update(featureFlagsTable)
    .set({ isEnabled, updatedAt: new Date().toISOString() })
    .where(and(eq(featureFlagsTable.tenantId, tenantId), eq(featureFlagsTable.featureKey, key)))
    .returning();

  if (!updated) {
    res.status(404).json({ error: "Feature not found" });
    return;
  }

  await db.insert(auditLogTable).values({
    actorUserId: req.auth!.sub,
    targetTenantId: tenantId,
    action: "feature.toggle",
    entityType: "feature_flag",
    entityId: updated.id,
    description: `Feature "${key}" ${isEnabled ? "enabled" : "disabled"}`,
  });

  res.json({
    data: {
      id: updated.id,
      feature_key: updated.featureKey,
      feature_name: updated.featureName,
      is_enabled: updated.isEnabled ?? true,
      category: updated.category,
    },
  });
});

/**
 * GET /api/configuration/summary — an aggregate of the tenant's configuration.
 * Company name comes from branding_config (the tenant's display name).
 */
router.get("/summary", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const [settings] = await db
    .select()
    .from(tenantSettingsTable)
    .where(eq(tenantSettingsTable.tenantId, tenantId))
    .limit(1);
  const [branding] = await db
    .select({ companyName: brandingConfigTable.companyName })
    .from(brandingConfigTable)
    .where(eq(brandingConfigTable.tenantId, tenantId))
    .limit(1);
  const features = await db
    .select()
    .from(featureFlagsTable)
    .where(eq(featureFlagsTable.tenantId, tenantId));
  const enabledFeatures = features.filter((f) => f.isEnabled).map((f) => f.featureKey);
  res.json({
    company_name: branding?.companyName ?? null,
    timezone: settings?.timezone ?? "Asia/Karachi",
    currency: settings?.currency ?? "PKR",
    language: settings?.language ?? "ur",
    features_enabled_count: enabledFeatures.length,
    features_total_count: features.length,
    enabled_features: enabledFeatures,
    integrations_configured: 0,
    integrations_enabled: [],
  });
});

export default router;
