import { Router, type IRouter } from "express";
import { requireAuth, requireSuperAdmin } from "../lib/auth.js";
import { adminService } from "../services/admin-service.js";
import { db } from "../db/index.js";
import { tenantTable } from "../db/schema/tenants.js";
import { auditLogTable } from "../db/schema/audit-log.js";
import { eq } from "drizzle-orm";

const router: IRouter = Router();

// All admin/tenant-management routes are super-admin only and platform-level
// (NO tenant scope — the requester is acting across tenants).
router.use(requireAuth, requireSuperAdmin());

/**
 * GET /api/admin/tenants — list all tenants (paginated, with user counts).
 */
router.get("/tenants", async (req, res): Promise<void> => {
  const page = Math.max(1, Number(req.query.page) || 1);
  const perPage = Math.min(100, Math.max(1, Number(req.query.perPage) || 20));
  const result = await adminService.listTenants(page, perPage);
  res.json({ tenants: result.tenants, total: result.total, page: result.page, perPage: result.perPage });
});

/**
 * GET /api/admin/tenants/:id — tenant details (configs, branding, flags, ...).
 */
router.get("/tenants/:id", async (req, res): Promise<void> => {
  const tenantId = Number(req.params.id);
  if (!Number.isInteger(tenantId)) {
    res.status(400).json({ error: "Invalid tenant id" });
    return;
  }
  const tenant = await adminService.getTenant(tenantId);
  if (!tenant) {
    res.status(404).json({ error: "Tenant not found" });
    return;
  }
  res.json({ ...tenant, users: await adminService.listTenantUsers(tenantId) });
});

/**
 * POST /api/admin/tenants — create a tenant with auto-provisioning.
 */
router.post("/tenants", async (req, res): Promise<void> => {
  const { name, slug, industry, timezone, currency, language } = req.body ?? {};
  if (typeof name !== "string" || !name.trim() || typeof slug !== "string" || !slug.trim()) {
    res.status(400).json({ error: "name and slug are required" });
    return;
  }
  try {
    const tenant = await adminService.createTenant({ name, slug, industry, timezone, currency, language }, req.auth!.sub);
    res.status(201).json({ data: tenant });
  } catch (err) {
    const e = err as Error & { status?: number };
    if (e.status) {
      res.status(e.status).json({ error: e.message });
      return;
    }
    throw err;
  }
});

/**
 * PUT /api/admin/tenants/:id — update tenant details and/or status.
 */
router.put("/tenants/:id", async (req, res): Promise<void> => {
  const tenantId = Number(req.params.id);
  if (!Number.isInteger(tenantId)) {
    res.status(400).json({ error: "Invalid tenant id" });
    return;
  }
  try {
    const updated = await adminService.updateTenant(tenantId, req.body ?? {}, req.auth!.sub);
    res.json({ data: updated });
  } catch (err) {
    const e = err as Error & { status?: number };
    if (e.status) {
      res.status(e.status).json({ error: e.message });
      return;
    }
    throw err;
  }
});

/**
 * PUT /api/admin/tenants/:id/status — activate/deactivate/suspend a tenant.
 */
router.put("/tenants/:id/status", async (req, res): Promise<void> => {
  const tenantId = Number(req.params.id);
  const { status } = req.body ?? {};
  if (!Number.isInteger(tenantId)) {
    res.status(400).json({ error: "Invalid tenant id" });
    return;
  }
  if (!["active", "suspended", "inactive"].includes(status)) {
    res.status(400).json({ error: "status must be active, suspended, or inactive" });
    return;
  }
  try {
    const updated = await adminService.updateTenant(tenantId, { status }, req.auth!.sub);
    res.json({ data: updated });
  } catch (err) {
    const e = err as Error & { status?: number };
    if (e.status) {
      res.status(e.status).json({ error: e.message });
      return;
    }
    throw err;
  }
});

/**
 * GET /api/admin/tenants/:id/stats — tenant statistics.
 */
router.get("/tenants/:id/stats", async (req, res): Promise<void> => {
  const tenantId = Number(req.params.id);
  if (!Number.isInteger(tenantId)) {
    res.status(400).json({ error: "Invalid tenant id" });
    return;
  }
  const stats = await adminService.getTenantStats(tenantId);
  res.json(stats);
});

/**
 * POST /api/admin/tenants/:id/admins — assign a user as Admin within a tenant.
 */
router.post("/tenants/:id/admins", async (req, res): Promise<void> => {
  const tenantId = Number(req.params.id);
  const { userId, role } = req.body ?? {};
  if (!Number.isInteger(tenantId)) {
    res.status(400).json({ error: "Invalid tenant id" });
    return;
  }
  if (!Number.isInteger(userId)) {
    res.status(400).json({ error: "userId is required" });
    return;
  }
  const updated = await adminService.assignUserToTenant(tenantId, userId, role ?? "Admin");
  await db.insert(auditLogTable).values({
    actorUserId: req.auth!.sub,
    targetTenantId: tenantId,
    action: "tenant.assign-admin",
    entityType: "user",
    entityId: userId,
    description: `User assigned to tenant ${tenantId}`,
  });
  res.json({ data: updated });
});

/**
 * POST /api/admin/tenants/:id/users — create a new user within a tenant.
 */
router.post("/tenants/:id/users", async (req, res): Promise<void> => {
  const tenantId = Number(req.params.id);
  const { username, displayName, password, role } = req.body ?? {};
  if (!Number.isInteger(tenantId)) {
    res.status(400).json({ error: "Invalid tenant id" });
    return;
  }
  if (!username || !displayName || typeof password !== "string" || password.length < 6) {
    res.status(400).json({ error: "username, displayName, and password (>=6 chars) are required" });
    return;
  }
  const created = await adminService.createTenantUser(tenantId, username, displayName, password, role ?? "Admin");
  await db.insert(auditLogTable).values({
    actorUserId: req.auth!.sub,
    targetTenantId: tenantId,
    action: "tenant.create-user",
    entityType: "user",
    entityId: created.id,
    description: `User "${username}" created in tenant ${tenantId}`,
  });
  res.status(201).json({ data: created });
});

/**
 * POST /api/admin/switch-tenant/:id — switch the super-admin's active tenant.
 *
 * NOTE (issue #219 Q1/Q3d, Option B): we do NOT re-issue a bearer token. The
 * active tenant is carried by the X-Tenant-Id header on subsequent requests.
 * This endpoint validates the target tenant is accessible and records an audit
 * entry; it returns tenant metadata (no new token).
 */
router.post("/switch-tenant/:id", async (req, res): Promise<void> => {
  const tenantId = Number(req.params.id);
  if (!Number.isInteger(tenantId)) {
    res.status(400).json({ error: "Invalid tenant id" });
    return;
  }
  const [tenant] = await db
    .select({ id: tenantTable.id, name: tenantTable.name, status: tenantTable.status })
    .from(tenantTable)
    .where(eq(tenantTable.id, tenantId))
    .limit(1);
  if (!tenant) {
    res.status(404).json({ error: "Tenant not found" });
    return;
  }
  await db.insert(auditLogTable).values({
    actorUserId: req.auth!.sub,
    targetTenantId: tenantId,
    action: "tenant.switch",
    entityType: "tenant",
    entityId: tenantId,
    description: `Super-admin switched active tenant to "${tenant.name}"`,
  });
  res.json({ tenant_id: tenant.id, tenant_name: tenant.name, status: tenant.status });
});

export default router;
