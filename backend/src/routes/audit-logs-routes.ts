import { Router, type IRouter } from "express";
import { desc, and, gte, lte, eq, like, or, count } from "drizzle-orm";
import { db } from "../db/index.js";
import { auditLogTable } from "../db/schema/audit-log.js";
import { loadRolePermissions, requireAuth } from "../lib/auth.js";
import { activeTenantId } from "../middleware/tenant-context.js";

const router: IRouter = Router();
router.use(requireAuth);

/**
 * GET /api/audit-logs — query the audit trail.
 *
 * Scope:
 *  - Super-admin sees ALL tenant/platform audit entries (optionally filtered
 *    by ?tenantId).
 *  - Tenant users see only their own tenant's audit entries (targetTenantId =
 *    their home tenant), regardless of tenant param.
 *
 * Filters: action, entityType, from/to (ISO dates), page, perPage, search
 * (matches actor/action/entity description).
 */
router.get("/", async (req, res): Promise<void> => {
  const perms = await loadRolePermissions(req.auth!.sub);
  const isSuper = perms?.isSuperAdmin ?? false;

  const q = req.query as Record<string, string | undefined>;
  const page = Math.max(1, Number(q.page) || 1);
  const perPage = Math.min(100, Math.max(1, Number(q.perPage) || 20));
  const offset = (page - 1) * perPage;

  const conditions = [];

  if (isSuper) {
    // Super-admin may filter by target tenant or see all.
    if (q.tenantId) {
      const tid = Number(q.tenantId);
      if (Number.isInteger(tid)) conditions.push(eq(auditLogTable.targetTenantId, tid));
    }
  } else {
    // Tenant user: only their own tenant's audits.
    const tenantId = activeTenantId(req);
    conditions.push(eq(auditLogTable.targetTenantId, tenantId));
  }

  if (q.action) conditions.push(like(auditLogTable.action, `%${q.action}%`));
  if (q.entityType) conditions.push(eq(auditLogTable.entityType, q.entityType));
  if (q.from) conditions.push(gte(auditLogTable.createdAt, q.from));
  if (q.to) conditions.push(lte(auditLogTable.createdAt, q.to));
  if (q.search) {
    conditions.push(or(
      like(auditLogTable.action, `%${q.search}%`),
      like(auditLogTable.description ?? "", `%${q.search}%`),
    ));
  }

  const where = conditions.length > 0 ? and(...conditions) : undefined;

  const [{ total }] = await db
    .select({ total: count() })
    .from(auditLogTable)
    .where(where);

  const rows = await db
    .select()
    .from(auditLogTable)
    .where(where)
    .orderBy(desc(auditLogTable.createdAt))
    .limit(perPage)
    .offset(offset);

  res.json({
    total,
    page,
    perPage,
    totalPages: Math.ceil(total / perPage),
    rows: rows.map((r) => ({
      id: r.id,
      actorUserId: r.actorUserId,
      actorTenantId: r.actorTenantId,
      targetTenantId: r.targetTenantId,
      action: r.action,
      entityType: r.entityType,
      entityId: r.entityId,
      description: r.description,
      ipAddress: r.ipAddress,
      createdAt: r.createdAt,
    })),
  });
});

export default router;
