import {
  pgTable,
  serial,
  text,
  integer,
  boolean,
  timestamp,
  date,
  numeric,
  bigint,
  jsonb,
  uniqueIndex,
  index,
  unique,
  varchar,
} from "drizzle-orm/pg-core";

// ─── Tenants ────────────────────────────────────────────────────────────────
// The platform-level tenant. Each tenant is an independent organization
// (e.g. a textile factory). All business, master, transactional, config,
// user, and role data belongs to exactly one tenant (via tenant_id FK).
// status is a plain varchar in the DB (matching the original migration) with
// allowed values active|suspended|inactive enforced at the service layer.
export const tenantTable = pgTable(
  "tenants",
  {
    id: serial("id").primaryKey(),
    name: text("name").notNull(),
    slug: text("slug").notNull(),
    industry: text("industry"),
    country: text("country").default("Pakistan"),
    timezone: text("timezone").default("Asia/Karachi"),
    currency: text("currency").default("PKR"),
    language: text("language").default("ur"),
    status: varchar("status", { length: 50 }).default("active"),
    createdAt: timestamp("created_at", { mode: "string" }).defaultNow(),
    updatedAt: timestamp("updated_at", { mode: "string" }).defaultNow(),
    metadata: jsonb("metadata"),
  },
  (t) => [
    uniqueIndex("tenants_name_key").on(t.name),
    uniqueIndex("tenants_slug_key").on(t.slug),
  ],
);

// ─── Tenant settings ────────────────────────────────────────────────────────
// Company-level configuration for a tenant (tax, branding-independent company
// details, formats). One row per tenant.
export const tenantSettingsTable = pgTable(
  "tenant_settings",
  {
    id: serial("id").primaryKey(),
    tenantId: integer("tenant_id")
      .notNull()
      .references(() => tenantTable.id, { onDelete: "cascade" }),
    companyRegistrationNumber: text("company_registration_number"),
    companyTaxId: text("company_tax_id"),
    companyBankAccount: text("company_bank_account"),
    companyPhone: text("company_phone"),
    companyEmail: text("company_email"),
    companyWebsite: text("company_website"),
    companyAddress: text("company_address"),
    companyCity: text("company_city"),
    companyProvince: text("company_province"),
    companyPostalCode: text("company_postal_code"),
    companyCountry: text("company_country").default("Pakistan"),
    businessType: text("business_type"),
    industryCategory: text("industry_category"),
    employeeCount: integer("employee_count"),
    annualRevenue: bigint("annual_revenue", { mode: "number" }),
    fiscalYearStart: date("fiscal_year_start"),
    fiscalYearEnd: date("fiscal_year_end"),
    timezone: text("timezone").default("Asia/Karachi"),
    currency: text("currency").default("PKR"),
    language: text("language").default("ur"),
    dateFormat: text("date_format").default("DD/MM/YYYY"),
    numberFormat: text("number_format").default("1,234.56"),
    taxEnabled: boolean("tax_enabled").default(true),
    defaultTaxRate: numeric("default_tax_rate", { precision: 5, scale: 2 }).default("17.00"),
    taxMethod: text("tax_method").default("inclusive"),
  },
  (t) => [
    uniqueIndex("uq_tenant_settings_tenant").on(t.tenantId),
  ],
);

// ─── Branding config ────────────────────────────────────────────────────────
// Visual/branding identity for a tenant. One row per tenant.
export const brandingConfigTable = pgTable(
  "branding_config",
  {
    id: serial("id").primaryKey(),
    tenantId: integer("tenant_id")
      .notNull()
      .references(() => tenantTable.id, { onDelete: "cascade" }),
    companyName: text("company_name").notNull(),
    companyShortName: text("company_short_name"),
    logoUrl: text("logo_url"),
    logoFilename: text("logo_filename"),
    logoStoragePath: text("logo_storage_path"),
    faviconUrl: text("favicon_url"),
    primaryColor: text("primary_color").default("#1F2937"),
    secondaryColor: text("secondary_color").default("#3B82F6"),
    accentColor: text("accent_color").default("#F59E0B"),
    textColor: text("text_color").default("#111827"),
    backgroundColor: text("background_color").default("#FFFFFF"),
    borderColor: text("border_color").default("#E5E7EB"),
    navbarBackground: text("navbar_background").default("#1F2937"),
    navbarTextColor: text("navbar_text_color").default("#FFFFFF"),
    sidebarBackground: text("sidebar_background").default("#F9FAFB"),
    sidebarTextColor: text("sidebar_text_color").default("#111827"),
    accentHoverColor: text("accent_hover_color"),
    successColor: text("success_color").default("#10B981"),
    warningColor: text("warning_color").default("#F59E0B"),
    errorColor: text("error_color").default("#EF4444"),
    infoColor: text("info_color").default("#3B82F6"),
    fontFamily: text("font_family").default("Inter, sans-serif"),
    fontSizeBase: integer("font_size_base").default(16),
    borderRadius: integer("border_radius").default(6),
    buttonStyle: text("button_style").default("rounded"),
  },
  (t) => [
    uniqueIndex("uq_branding_config_tenant").on(t.tenantId),
  ],
);

// ─── Feature flags ──────────────────────────────────────────────────────────
// Per-tenant feature toggles + limits.
export const featureFlagsTable = pgTable(
  "feature_flags",
  {
    id: serial("id").primaryKey(),
    tenantId: integer("tenant_id")
      .notNull()
      .references(() => tenantTable.id, { onDelete: "cascade" }),
    featureKey: text("feature_key").notNull(),
    featureName: text("feature_name").notNull(),
    description: text("description"),
    isEnabled: boolean("is_enabled").default(true),
    isBeta: boolean("is_beta").default(false),
    category: text("category"),
    maxUsers: integer("max_users"),
    maxOrders: integer("max_orders"),
    maxStorageMb: integer("max_storage_mb"),
    maxApiCallsPerMonth: integer("max_api_calls_per_month"),
    enabledAt: timestamp("enabled_at", { mode: "string" }),
    disabledAt: timestamp("disabled_at", { mode: "string" }),
    createdAt: timestamp("created_at", { mode: "string" }).defaultNow(),
    updatedAt: timestamp("updated_at", { mode: "string" }).defaultNow(),
  },
  (t) => [
    uniqueIndex("uq_feature_flags_key").on(t.tenantId, t.featureKey),
    index("idx_feature_flags_tenant").on(t.tenantId),
    index("idx_feature_flags_tenant_enabled").on(t.tenantId, t.isEnabled),
    index("idx_feature_flags_category").on(t.tenantId, t.category),
  ],
);

// ─── Theme presets ──────────────────────────────────────────────────────────
// Predefined color themes available to a tenant.
export const themePresetsTable = pgTable(
  "theme_presets",
  {
    id: serial("id").primaryKey(),
    tenantId: integer("tenant_id")
      .notNull()
      .references(() => tenantTable.id, { onDelete: "cascade" }),
    presetName: text("preset_name").notNull(),
    presetKey: text("preset_key").notNull(),
    description: text("description"),
    primaryColor: text("primary_color"),
    secondaryColor: text("secondary_color"),
    accentColor: text("accent_color"),
    textColor: text("text_color"),
    backgroundColor: text("background_color"),
    navbarColor: text("navbar_color"),
    navbarTextColor: text("navbar_text_color"),
    sidebarColor: text("sidebar_color"),
    sidebarTextColor: text("sidebar_text_color"),
    accentHoverColor: text("accent_hover_color"),
    isDefault: boolean("is_default").default(false),
    createdAt: timestamp("created_at", { mode: "string" }).defaultNow(),
    updatedAt: timestamp("updated_at", { mode: "string" }).defaultNow(),
  },
  (t) => [
    uniqueIndex("uq_theme_preset_key").on(t.tenantId, t.presetKey),
    index("idx_theme_preset_tenant").on(t.tenantId),
    index("idx_theme_preset_default").on(t.tenantId, t.isDefault),
  ],
);

// ─── Session settings ───────────────────────────────────────────────────────
// Per-tenant auth/session security policy. One row per tenant.
export const sessionSettingsTable = pgTable(
  "session_settings",
  {
    id: serial("id").primaryKey(),
    tenantId: integer("tenant_id")
      .notNull()
      .references(() => tenantTable.id, { onDelete: "cascade" }),
    sessionTimeoutMinutes: integer("session_timeout_minutes").default(30),
    rememberMeEnabled: boolean("remember_me_enabled").default(true),
    rememberMeDurationDays: integer("remember_me_duration_days").default(30),
    maxConcurrentSessions: integer("max_concurrent_sessions").default(5),
    forcePasswordChangeDays: integer("force_password_change_days").default(90),
    passwordExpiryEnabled: boolean("password_expiry_enabled").default(false),
    twoFactorRequiredForAdmins: boolean("two_factor_required_for_admins").default(true),
    twoFactorOptionalForUsers: boolean("two_factor_optional_for_users").default(false),
    deviceManagementEnabled: boolean("device_management_enabled").default(true),
    maxDevicesPerUser: integer("max_devices_per_user").default(5),
    ipWhitelistEnabled: boolean("ip_whitelist_enabled").default(false),
    ipWhitelist: text("ip_whitelist"),
    createdAt: timestamp("created_at", { mode: "string" }).defaultNow(),
    updatedAt: timestamp("updated_at", { mode: "string" }).defaultNow(),
  },
  (t) => [
    uniqueIndex("session_settings_tenant_id_key").on(t.tenantId),
  ],
);

// ─── OAuth providers ────────────────────────────────────────────────────────
// Per-tenant external OAuth/SSO provider configuration.
export const oauthProvidersTable = pgTable(
  "oauth_providers",
  {
    id: serial("id").primaryKey(),
    tenantId: integer("tenant_id")
      .notNull()
      .references(() => tenantTable.id, { onDelete: "cascade" }),
    providerName: text("provider_name").notNull(),
    providerType: text("provider_type"),
    clientId: text("client_id"),
    clientSecret: text("client_secret"),
    redirectUri: text("redirect_uri"),
    scope: text("scope"),
    isEnabled: boolean("is_enabled").default(false),
    isConfigured: boolean("is_configured").default(false),
    configJson: jsonb("config_json"),
    createdAt: timestamp("created_at", { mode: "string" }).defaultNow(),
    updatedAt: timestamp("updated_at", { mode: "string" }).defaultNow(),
  },
  (t) => [
    uniqueIndex("uq_oauth_provider").on(t.tenantId, t.providerName),
    index("idx_oauth_providers_tenant").on(t.tenantId, t.isEnabled),
  ],
);

export type Tenant = typeof tenantTable.$inferSelect;
export type InsertTenant = typeof tenantTable.$inferInsert;
export type TenantSettings = typeof tenantSettingsTable.$inferSelect;
export type BrandingConfig = typeof brandingConfigTable.$inferSelect;
export type FeatureFlags = typeof featureFlagsTable.$inferSelect;
export type ThemePresets = typeof themePresetsTable.$inferSelect;
export type SessionSettings = typeof sessionSettingsTable.$inferSelect;
export type OauthProviders = typeof oauthProvidersTable.$inferSelect;
