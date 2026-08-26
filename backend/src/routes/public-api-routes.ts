import { Router, type IRouter } from "express";
import { eq, desc, sql, sum, count } from "drizzle-orm";
import { db } from "../db/index.js";
import { requireApiKey } from "../middleware/require-api-key.js";
import { auditLogTable } from "../db/schema/audit-log.js";
import {
  transactionHeaderTable,
  transactionDetailTable,
} from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";

/**
 * /api/v1 — versioned, API-key-authenticated programmatic surface
 * (issue #219 2.4). Every route uses requireApiKey which sets the key's tenant
 * context. No X-Tenant-Id needed: the key is bound to a single tenant.
 */
const router: IRouter = Router();
router.use(requireApiKey);

/** GET /api/v1/whoami — tenant + key identity for the caller. */
router.get("/whoami", (req, res) => {
  res.json({
    tenantId: activeTenantId(req),
    keyLabel: req.auth!.username,
    keyId: Math.abs(req.auth!.sub as number),
    mode: "api-key",
  });
});

/** GET /api/v1/dashboard — KPI summary for the key's tenant. */
router.get("/dashboard", async (_req, res): Promise<void> => {
  const tenantId = activeTenantId(_req);
  const [{ headers }] = await db
    .select({ headers: count() })
    .from(transactionHeaderTable)
    .where(eq(transactionHeaderTable.tenantId, tenantId));
  const [{ details }] = await db
    .select({ details: count() })
    .from(transactionDetailTable)
    .where(eq(transactionDetailTable.tenantId, tenantId));
  const [{ qty }] = await db
    .select({ qty: sum(sql`coalesce(${transactionDetailTable.quantity}, 0)`) })
    .from(transactionDetailTable)
    .where(eq(transactionDetailTable.tenantId, tenantId));
  res.json({ tenantId, transactionHeaders: headers, transactionDetails: details, totalQuantity: qty });
});

/** GET /api/v1/audit-logs — recent audit entries for the key's tenant. */
router.get("/audit-logs", async (_req, res): Promise<void> => {
  const tenantId = activeTenantId(_req);
  const rows = await db
    .select({
      id: auditLogTable.id,
      action: auditLogTable.action,
      entityType: auditLogTable.entityType,
      entityId: auditLogTable.entityId,
      description: auditLogTable.description,
      createdAt: auditLogTable.createdAt,
    })
    .from(auditLogTable)
    .where(eq(auditLogTable.targetTenantId, tenantId))
    .orderBy(desc(auditLogTable.createdAt))
    .limit(50);
  res.json({ tenantId, total: rows.length, rows });
});

export default router;
