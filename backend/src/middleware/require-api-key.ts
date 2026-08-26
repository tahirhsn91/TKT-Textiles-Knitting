import { createHash } from "node:crypto";
import type { NextFunction, Request, Response } from "express";
import { eq, and, isNull } from "drizzle-orm";
import { db } from "../db/index.js";
import { apiKeyTable } from "../db/schema/api-keys.js";

/**
 * requireApiKey — authenticate a request via an `X-API-Key` header
 * (issue #219 2.4). Use INSTEAD of requireAuth + resolveTenant on routes meant
 * for API-key programmatic access.
 *
 * The key is stored as a sha256 hash. On success it:
 *   - sets req.auth to a synthetic admin-in-tenant identity (isAdmin: true,
 *     isSuperAdmin: false) so existing requirePermission guards pass within
 *     the key's tenant;
 *   - sets req.tenantId to the key's tenant so activeTenantId() scopes queries
 *     correctly;
 *   - updates lastUsedAt (best-effort).
 *
 * Revoked or expired keys are rejected 401/403.
 */
export async function requireApiKey(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const header = req.headers["x-api-key"];
  if (!header) {
    res.status(401).json({ error: "API key required (X-API-Key header missing)" });
    return;
  }
  const raw = String(header);
  const hash = createHash("sha256").update(raw).digest("hex");

  const key = await db
    .select()
    .from(apiKeyTable)
    .where(eq(apiKeyTable.keyHash, hash))
    .limit(1);

  if (!key[0]) {
    res.status(401).json({ error: "Invalid API key" });
    return;
  }
  const k = key[0];
  if (k.revokedAt) {
    res.status(403).json({ error: "API key has been revoked" });
    return;
  }
  if (k.expiresAt && k.expiresAt.getTime() < Date.now()) {
    res.status(403).json({ error: "API key has expired" });
    return;
  }

  // Synthetic identity: admin within the key's tenant. Negative sub avoids
  // colliding with real user ids (which are positive serials).
  req.auth = {
    sub: -(k.id),
    username: k.label,
    roleId: 0,
    role: "apikey",
    isAdmin: true,
    isSuperAdmin: false,
    tenantId: k.tenantId,
  };
  req.tenantId = k.tenantId;

  // Best-effort last-used update (fire-and-forget).
  void db
    .update(apiKeyTable)
    .set({ lastUsedAt: new Date() })
    .where(eq(apiKeyTable.id, k.id));

  next();
}
