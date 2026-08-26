import { Router, type IRouter } from "express";
import { randomBytes, createHash } from "node:crypto";
import { eq, and, isNull, desc } from "drizzle-orm";
import { db } from "../db/index.js";
import { apiKeyTable } from "../db/schema/api-keys.js";
import { auditLogTable } from "../db/schema/audit-log.js";
import { loadRolePermissions, requireAuth, requirePermission } from "../lib/auth.js";
import { activeTenantId } from "../middleware/tenant-context.js";

const router: IRouter = Router();
router.use(requireAuth);
// Only users-admins (tenant Admin or super-admin) manage API keys.
router.use(requirePermission("users"));

/** Generate a new raw API key + its sha256 hash + display hint. */
function generateKey() {
  const raw = `tkt_${randomBytes(24).toString("base64url")}`;
  const hash = createHash("sha256").update(raw).digest("hex");
  const hint = raw.slice(-8);
  return { raw, hash, hint };
}

/**
 * GET /api/keys — list the active tenant's API keys. Requires super-admin or
 * tenant-admin (uses users permission as an admin-marker).
 */
router.get("/", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const rows = await db
    .select()
    .from(apiKeyTable)
    .where(and(eq(apiKeyTable.tenantId, tenantId), isNull(apiKeyTable.revokedAt)))
    .orderBy(desc(apiKeyTable.createdAt));

  const items = rows.map((k) => ({
    id: k.id,
    label: k.label,
    keyHint: k.keyHint,
    lastUsedAt: k.lastUsedAt,
    expiresAt: k.expiresAt,
    revokedAt: k.revokedAt,
    createdAt: k.createdAt,
  }));
  res.json(items);
});

/**
 * POST /api/keys — create an API key. The raw key is returned ONCE.
 */
router.post("/", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const { label, expiresAt } = req.body ?? {};
  if (!label || typeof label !== "string") {
    res.status(400).json({ error: "label is required" });
    return;
  }

  const { raw, hash, hint } = generateKey();
  const [key] = await db
    .insert(apiKeyTable)
    .values({ tenantId, label, keyHash: hash, keyHint: hint, createdBy: req.auth!.sub, expiresAt: expiresAt ?? null })
    .returning();

  await db.insert(auditLogTable).values({
    actorUserId: req.auth!.sub,
    actorTenantId: tenantId,
    targetTenantId: tenantId,
    action: "apikey.create",
    entityType: "api_key",
    entityId: key.id,
    description: `Created API key "${label}" for tenant ${tenantId}`,
  });

  res.status(201).json({
    id: key.id,
    label: key.label,
    keyHint: hint,
    apiKey: raw, // shown once
    expiresAt: key.expiresAt,
    createdAt: key.createdAt,
  });
});

/**
 * POST /api/keys/:id/revoke — revoke an API key (idempotent).
 */
router.post("/:id/revoke", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) {
    res.status(400).json({ error: "invalid id" });
    return;
  }
  const [key] = await db
    .update(apiKeyTable)
    .set({ revokedAt: new Date() })
    .where(and(eq(apiKeyTable.id, id), eq(apiKeyTable.tenantId, tenantId)))
    .returning();
  if (!key) {
    res.status(404).json({ error: "key not found" });
    return;
  }
  await db.insert(auditLogTable).values({
    actorUserId: req.auth!.sub,
    actorTenantId: tenantId,
    targetTenantId: tenantId,
    action: "apikey.revoke",
    entityType: "api_key",
    entityId: key.id,
    description: `Revoked API key "${key.label}" for tenant ${tenantId}`,
  });
  res.json({ ok: true, id });
});

// Express 5: prefer the modern handler signatures; the Promise<void> returns
// above keep existing middleware-style behaviour for requireAuth.

export default router;
