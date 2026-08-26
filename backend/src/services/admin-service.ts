import { eq, and, sql, desc } from "drizzle-orm";
import { db } from "../db/index.js";
import {
  tenantTable,
  tenantSettingsTable,
  brandingConfigTable,
  featureFlagsTable,
  themePresetsTable,
  sessionSettingsTable,
  oauthProvidersTable,
} from "../db/schema/tenants.js";
import { userTable, roleTable, rolePermissionTable } from "../db/schema/users.js";
import { auditLogTable } from "../db/schema/audit-log.js";
import { transactionHeaderTable } from "../db/schema/transactions.js";
import { transactionDetailTable } from "../db/schema/transactions.js";
import argon2 from "argon2";
import { logger } from "../lib/logger.js";
import { DEFAULT_THEME_PRESETS } from "../lib/theme-presets.js";

export interface CreateTenantInput {
  name: string;
  slug: string;
  industry?: string;
  country?: string;
  timezone?: string;
  currency?: string;
  language?: string;
}

export interface UpdateTenantInput {
  name?: string;
  slug?: string;
  industry?: string;
  country?: string;
  timezone?: string;
  currency?: string;
  language?: string;
  status?: "active" | "suspended" | "inactive";
  metadata?: Record<string, unknown>;
}

// Default feature flags provisioned to every new tenant (issue #219 Q7a).
const DEFAULT_FEATURE_FLAGS = [
  { featureKey: "dashboard", featureName: "Dashboard", isEnabled: true },
  { featureKey: "invoicing", featureName: "FBR Invoicing", isEnabled: true },
  { featureKey: "reports", featureName: "Reports", isEnabled: true },
  { featureKey: "payroll", featureName: "Payroll", isEnabled: true },
];

export const adminService = {
  /** Super-admin: list all tenants (paginated) with user counts. */
  async listTenants(page = 1, perPage = 20) {
    const offset = (page - 1) * perPage;
    const tenants = await db
      .select({
        id: tenantTable.id,
        name: tenantTable.name,
        slug: tenantTable.slug,
        industry: tenantTable.industry,
        status: tenantTable.status,
        timezone: tenantTable.timezone,
        currency: tenantTable.currency,
        language: tenantTable.language,
        createdAt: tenantTable.createdAt,
        userCount: sql<number>`count(${userTable.id})`,
      })
      .from(tenantTable)
      .leftJoin(userTable, eq(userTable.tenantId, tenantTable.id))
      .groupBy(tenantTable.id)
      .orderBy(desc(tenantTable.createdAt))
      .limit(perPage)
      .offset(offset);

    const [{ total }] = await db
      .select({ total: sql<number>`count(*)`.mapWith(Number) })
      .from(tenantTable);
    return { tenants, total, page, perPage };
  },

  /** Super-admin: get one tenant with its provisioning configs. */
  async getTenant(tenantId: number) {
    const [tenant] = await db
      .select()
      .from(tenantTable)
      .where(eq(tenantTable.id, tenantId))
      .limit(1);
    if (!tenant) return null;

    const [settings] = await db
      .select()
      .from(tenantSettingsTable)
      .where(eq(tenantSettingsTable.tenantId, tenantId))
      .limit(1);
    const [branding] = await db
      .select()
      .from(brandingConfigTable)
      .where(eq(brandingConfigTable.tenantId, tenantId))
      .limit(1);
    const flags = await db
      .select()
      .from(featureFlagsTable)
      .where(eq(featureFlagsTable.tenantId, tenantId));
    const presets = await db
      .select()
      .from(themePresetsTable)
      .where(eq(themePresetsTable.tenantId, tenantId));
    const [sessions] = await db
      .select()
      .from(sessionSettingsTable)
      .where(eq(sessionSettingsTable.tenantId, tenantId))
      .limit(1);
    const providers = await db
      .select()
      .from(oauthProvidersTable)
      .where(eq(oauthProvidersTable.tenantId, tenantId));

    return { ...tenant, settings, branding, flags, presets, sessions, providers };
  },

  /** Super-admin: create a tenant with auto-provisioning (issue #219 Q7a). */
  async createTenant(input: CreateTenantInput, actorUserId: number) {
    // Normalize slug; enforce uniqueness.
    const slug = input.slug.trim().toLowerCase().replace(/[^a-z0-9-]/g, "-");
    const existing = await db
      .select({ id: tenantTable.id })
      .from(tenantTable)
      .where(eq(tenantTable.slug, slug))
      .limit(1);
    if (existing.length > 0) {
      const err = new Error("A tenant with this slug already exists");
      (err as Error & { status?: number }).status = 409;
      throw err;
    }

    const created = await db.transaction(async (tx) => {
      const [tenant] = await tx
        .insert(tenantTable)
        .values({
          name: input.name,
          slug,
          industry: input.industry ?? null,
          country: input.country ?? "Pakistan",
          timezone: input.timezone ?? "Asia/Karachi",
          currency: input.currency ?? "PKR",
          language: input.language ?? "ur",
          status: "active",
        })
        .returning();

      // Provision default tenant settings.
      await tx.insert(tenantSettingsTable).values({ tenantId: tenant.id });
      // Provision default branding.
      await tx.insert(brandingConfigTable).values({
        tenantId: tenant.id,
        companyName: input.name,
      });
      // Provision default feature flags.
      await tx.insert(featureFlagsTable).values(
        DEFAULT_FEATURE_FLAGS.map((f) => ({ tenantId: tenant.id, ...f })),
      );
      // Provision default theme presets (issue #219 1.2 — full colour surface).
      await tx.insert(themePresetsTable).values(
        DEFAULT_THEME_PRESETS.map((p) => ({ tenantId: tenant.id, ...p })),
      );
      // Provision default session settings.
      await tx.insert(sessionSettingsTable).values({ tenantId: tenant.id });

      // Provision per-tenant roles (issue #219 Q5c/Q7a): Admin, Manager,
      // Supervisor, each scoped to this tenant. The Admin role is is_admin.
      const [adminRole] = await tx
        .insert(roleTable)
        .values({ name: "Admin", isAdmin: true, tenantId: tenant.id })
        .returning({ id: roleTable.id });
      await tx.insert(roleTable).values([
        { name: "Manager", isAdmin: false, tenantId: tenant.id },
        { name: "Supervisor", isAdmin: false, tenantId: tenant.id },
      ]);
      // Give the tenant Admin full route access within the tenant via a
      // wildcard permission row (is_admin already implies full access, but we
      // also seed a wildcard module row for consistency with the matrix).
      await tx.insert(rolePermissionTable).values({
        roleId: adminRole.id,
        moduleId: "*",
      });

      return tenant;
    });

    // Audit trail (issue #219 audit requirements).
    await db.insert(auditLogTable).values({
      actorUserId,
      actorTenantId: null,
      targetTenantId: created.id,
      action: "tenant.create",
      entityType: "tenant",
      entityId: created.id,
      description: `Tenant "${created.name}" (${slug}) created with auto-provisioning`,
    });

    logger.info({ tenantId: created.id }, "tenant created");
    return created;
  },

  /** Super-admin: update tenant details and/or status. */
  async updateTenant(tenantId: number, input: UpdateTenantInput, actorUserId: number) {
    const [existing] = await db
      .select({ id: tenantTable.id })
      .from(tenantTable)
      .where(eq(tenantTable.id, tenantId))
      .limit(1);
    if (!existing) {
      const err = new Error("Tenant not found");
      (err as Error & { status?: number }).status = 404;
      throw err;
    }

    const patch: Record<string, unknown> = { updatedAt: new Date() };
    if (input.name !== undefined) patch.name = input.name;
    if (input.slug !== undefined) {
      const slug = input.slug.trim().toLowerCase().replace(/[^a-z0-9-]/g, "-");
      patch.slug = slug;
    }
    if (input.industry !== undefined) patch.industry = input.industry;
    if (input.country !== undefined) patch.country = input.country;
    if (input.timezone !== undefined) patch.timezone = input.timezone;
    if (input.currency !== undefined) patch.currency = input.currency;
    if (input.language !== undefined) patch.language = input.language;
    if (input.status !== undefined) patch.status = input.status;
    if (input.metadata !== undefined) patch.metadata = input.metadata;

    // Deactivation guard: never deactivate tenant 1 via this path if it would
    // strand the platform seed. (Q6b kept tenant 1 normal, but we still guard
    // public deactivation of the seeded tenant to avoid breaking the app.)
    if (patch.status === "inactive" && tenantId === 1) {
      const err = new Error("Tenant 1 (TKT Textiles) cannot be deactivated");
      (err as Error & { status?: number }).status = 400;
      throw err;
    }

    const [updated] = await db
      .update(tenantTable)
      .set(patch)
      .where(eq(tenantTable.id, tenantId))
      .returning();

    if (input.status !== undefined) {
      await db.insert(auditLogTable).values({
        actorUserId,
        targetTenantId: tenantId,
        action: `tenant.${input.status === "active" ? "activate" : input.status === "suspended" ? "suspend" : "deactivate"}`,
        entityType: "tenant",
        entityId: tenantId,
        description: `Tenant status set to ${input.status}`,
      });
    }

    return updated;
  },

  /** Super-admin: tenant statistics (users, invoices, config count). */
  async getTenantStats(tenantId: number) {
    const [{ userCount }] = await db
      .select({ userCount: sql<number>`count(*)`.mapWith(Number) })
      .from(userTable)
      .where(eq(userTable.tenantId, tenantId));
    const [{ roleCount }] = await db
      .select({ roleCount: sql<number>`count(*)`.mapWith(Number) })
      .from(roleTable)
      .where(eq(roleTable.tenantId, tenantId));
    const [{ transactionCount }] = await db
      .select({ transactionCount: sql<number>`count(*)`.mapWith(Number) })
      .from(transactionHeaderTable)
      .where(eq(transactionHeaderTable.tenantId, tenantId));
    // Activity: audit entries referencing this tenant (creation/updates/etc.).
    const [{ activityCount }] = await db
      .select({ activityCount: sql<number>`count(*)`.mapWith(Number) })
      .from(auditLogTable)
      .where(eq(auditLogTable.targetTenantId, tenantId));
    return { tenantId, userCount, roleCount, transactionCount, activityCount };
  },

  /**
   * Usage snapshot for the super-admin tenant panel (issue #219 2.2).
   * Resource-limited metrics (seats, records) used to monitor tenant load.
   */
  async getTenantUsage(tenantId: number) {
    const [tenant] = await db
      .select({ id: tenantTable.id, name: tenantTable.name, slug: tenantTable.slug, status: tenantTable.status })
      .from(tenantTable)
      .where(eq(tenantTable.id, tenantId))
      .limit(1);
    if (!tenant) {
      const err = new Error("Tenant not found");
      (err as Error & { status?: number }).status = 404;
      throw err;
    }

    const [{ users }] = await db.select({ users: sql<number>`count(*)`.mapWith(Number) }).from(userTable).where(eq(userTable.tenantId, tenantId));
    const [{ transactions }] = await db.select({ transactions: sql<number>`count(*)`.mapWith(Number) }).from(transactionHeaderTable).where(eq(transactionHeaderTable.tenantId, tenantId));
    const [{ totalRecords }] = await db.select({ totalRecords: sql<number>`count(*)`.mapWith(Number) }).from(transactionDetailTable).where(eq(transactionDetailTable.tenantId, tenantId));
    const [{ auditEvents }] = await db.select({ auditEvents: sql<number>`count(*)`.mapWith(Number) }).from(auditLogTable).where(eq(auditLogTable.targetTenantId, tenantId));

    return {
      tenantId,
      name: tenant.name,
      slug: tenant.slug,
      status: tenant.status,
      usage: {
        seats: { used: users, limit: null },           // plan limit (null = unlimited) — set on subscription
        transactions: { used: transactions, limit: null },
        records: { used: totalRecords, limit: null },
        auditEvents,
      },
    };
  },

  /**
   * Assign a user as an Admin (or any role) within a tenant. The user must
   * already be scoped to that tenant (or be a platform user being placed).
   * A new tenant Admin user can be created and assigned here.
   */
  async assignUserToTenant(tenantId: number, userId: number, roleName: string) {
    const [tenant] = await db
      .select({ id: tenantTable.id })
      .from(tenantTable)
      .where(eq(tenantTable.id, tenantId))
      .limit(1);
    if (!tenant) {
      const err = new Error("Tenant not found");
      (err as Error & { status?: number }).status = 404;
      throw err;
    }
    // Resolve the role id by (tenantId, name) or the tenant Admin role id 1 if omitted.
    let roleId: number;
    const [role] = await db
      .select({ id: roleTable.id })
      .from(roleTable)
      .where(and(eq(roleTable.tenantId, tenantId), eq(roleTable.name, roleName)))
      .limit(1);
    if (role) {
      roleId = role.id;
    } else {
      // Fall back to the seeded Admin role for this tenant (tenant-scoped).
      const [adminRole] = await db
        .select({ id: roleTable.id })
        .from(roleTable)
        .where(and(eq(roleTable.tenantId, tenantId), eq(roleTable.isAdmin, true)))
        .limit(1);
      if (!adminRole) throw new Error(`No Admin role configured for tenant ${tenantId}`);
      roleId = adminRole.id;
    }

    const [updated] = await db
      .update(userTable)
      .set({ roleId, tenantId })
      .where(eq(userTable.id, userId))
      .returning({ id: userTable.id, username: userTable.username });
    return updated;
  },

  /** Super-admin: move a user out of a tenant (detach, keep the account). */
  async removeUserFromTenant(userId: number) {
    const [updated] = await db
      .update(userTable)
      .set({ tenantId: null })
      .where(eq(userTable.id, userId))
      .returning({ id: userTable.id, username: userTable.username });
    return updated;
  },

  /** Super-admin: create a new tenant Admin user (assign initial password). */
  async createTenantUser(tenantId: number, username: string, displayName: string, password: string, roleName: string) {
    const [role] = await db
      .select({ id: roleTable.id })
      .from(roleTable)
      .where(and(eq(roleTable.tenantId, tenantId), eq(roleTable.name, roleName)))
      .limit(1);
    if (!role) {
      const err = new Error(`Role '${roleName}' not found for tenant`);
      (err as Error & { status?: number }).status = 404;
      throw err;
    }
    const hash = await argon2.hash(password);
    const [created] = await db
      .insert(userTable)
      .values({ username, displayName, passwordHash: hash, roleId: role.id, tenantId, isActive: true })
      .returning({ id: userTable.id, username: userTable.username });
    return created;
  },

  /** Super-admin: delete a tenant (and its cascade of tenant-owned data). */
  async deleteTenant(tenantId: number, actorUserId: number) {
    // Protect the seeded TKT Textiles tenant from deletion (Q6b safeguard).
    if (tenantId === 1) {
      const err = new Error("Tenant 1 (TKT Textiles) cannot be deleted");
      (err as Error & { status?: number }).status = 400;
      throw err;
    }
    const [existing] = await db
      .select({ id: tenantTable.id, name: tenantTable.name })
      .from(tenantTable)
      .where(eq(tenantTable.id, tenantId))
      .limit(1);
    if (!existing) {
      const err = new Error("Tenant not found");
      (err as Error & { status?: number }).status = 404;
      throw err;
    }
    const deleted = await db.transaction(async (tx) => {
      // Insert the audit entry FIRST (while the tenant still exists) so the
      // audit_log.target_tenant_id FK is satisfied; then delete the tenant
      // (cascade removes its tenant-owned data).
      await tx.insert(auditLogTable).values({
        actorUserId,
        targetTenantId: tenantId,
        action: "tenant.delete",
        entityType: "tenant",
        entityId: tenantId,
        description: `Tenant "${existing.name}" deleted`,
      });
      return tx
        .delete(tenantTable)
        .where(eq(tenantTable.id, tenantId))
        .returning({ id: tenantTable.id, name: tenantTable.name });
    });
    return deleted[0];
  },

  /** List users belonging to a tenant. */
  async listTenantUsers(tenantId: number) {
    return db
      .select({
        id: userTable.id,
        username: userTable.username,
        displayName: userTable.displayName,
        roleId: userTable.roleId,
        isActive: userTable.isActive,
      })
      .from(userTable)
      .where(eq(userTable.tenantId, tenantId))
      .orderBy(userTable.username);
  },
};

export type AdminService = typeof adminService;
