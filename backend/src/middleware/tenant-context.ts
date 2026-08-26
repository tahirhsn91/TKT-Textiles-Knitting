import { Request, Response, NextFunction } from "express";
import { eq } from "drizzle-orm";
import { db } from "../db/index.js";
import { tenantTable } from "../db/schema/tenants.js";
import { loadRolePermissions } from "../lib/auth.js";

/**
 * Express augmentation: the resolved active tenant context on the request.
 * Set by resolveTenant; consumed by requireTenant and by every route that
 * needs to scope its Drizzle queries.
 */
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      tenantId?: number | null;
    }
  }
}

export const TENANT_HEADER = "x-tenant-id";

function arrayAware(values: string | string[] | undefined): string | undefined {
  return Array.isArray(values) ? values[0] : values;
}

/**
 * Resolve the active tenant context for a request. Call AFTER requireAuth.
 *
 * Security model (issue #219 / Q2, Q8, Q3):
 *   - The tenant is NEVER taken from query params or body. It comes only from
 *     the X-Tenant-Id header (super-admin) or the user's home tenant (JWT).
 *   - Super-admin: the X-Tenant-Id header selects the active tenant. It must
 *     exist and be active. If absent -> 428 (Precondition Required), prompting
 *     the UI to ask the super-admin to pick a tenant.
 *   - Tenant user (Admin/Manager/Supervisor): their tenant is their home
 *     tenant (req.auth.tenantId). If they send an X-Tenant-Id that differs ->
 *     403 (cross-tenant attempt rejected). If their tenant is inactive they
 *     are blocked (403).
 *   - Active-status: non-super-admins are blocked on inactive tenants.
 *     Super-admins may still operate on an inactive tenant (with the active
 *     check skipped), per issue #219 Scenario 6.
 */
export async function resolveTenant(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  if (!req.auth) {
    res.status(401).json({ error: "Authentication required" });
    return;
  }

  const set = await loadRolePermissions(req.auth.sub);
  if (!set) {
    res.status(403).json({ error: "Account not found" });
    return;
  }

  const headerTenant = arrayAware(req.headers[TENANT_HEADER] as string | string[] | undefined);

  if (set.isSuperAdmin) {
    // Super-admin may act in ANY tenant, selected by header.
    if (!headerTenant) {
      res.status(428).json({
        error: "Select a tenant to continue",
        code: "TENANT_REQUIRED",
      });
      return;
    }
    const tenantId = Number(headerTenant);
    if (!Number.isInteger(tenantId) || tenantId <= 0) {
      res.status(400).json({ error: "Invalid tenant id" });
      return;
    }
    const tenant = await db
      .select({ id: tenantTable.id, status: tenantTable.status })
      .from(tenantTable)
      .where(eq(tenantTable.id, tenantId))
      .limit(1);
    if (!tenant[0]) {
      res.status(404).json({ error: "Tenant not found" });
      return;
    }
    // Super-admins may operate on inactive tenants too (override), so we do
    // NOT block here on status — the caller may still manage the tenant.
    req.tenantId = tenantId;
    next();
    return;
  }

  // Not a super-admin: tenant is their home tenant (from the JWT).
  const homeTenant = (req.auth as { tenantId?: number | null }).tenantId ?? null;
  if (homeTenant == null) {
    // A non-super-admin with no home tenant cannot operate in any tenant.
    res.status(403).json({ error: "No tenant assigned to this account" });
    return;
  }
  // Reject cross-tenant attempts: if the client sent an X-Tenant-Id header,
  // it MUST match the user's home tenant.
  if (headerTenant !== undefined && headerTenant !== "" && Number(headerTenant) !== homeTenant) {
    res.status(403).json({ error: "Cross-tenant access denied" });
    return;
  }
  // Block non-super-admins on inactive tenants.
  const tenant = await db
    .select({ id: tenantTable.id, status: tenantTable.status })
    .from(tenantTable)
    .where(eq(tenantTable.id, homeTenant))
    .limit(1);
  if (!tenant[0] || tenant[0].status !== "active") {
    res.status(403).json({ error: "Tenant is not active" });
    return;
  }
  req.tenantId = homeTenant;
  next();
}

/**
 * Ensure a tenant context is present on the request. Use after resolveTenant
 * on tenant-scoped routes. Super-admin with no selected tenant => 428.
 */
export function requireTenant(req: Request, res: Response, next: NextFunction): void {
  if (!req.tenantId) {
    res.status(428).json({
      error: "Select a tenant to continue",
      code: "TENANT_REQUIRED",
    });
    return;
  }
  next();
}

/**
 * Returns the resolved active tenant id for the request. Throws if none.
 * Convenience for route handlers that need the numeric tenant id to scope
 * their Drizzle queries.
 */
export function activeTenantId(req: Request): number {
  if (!req.tenantId) {
    throw new Error("Tenant context not found in request");
  }
  return req.tenantId;
}

export { loadRolePermissions };
