import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { eq } from "drizzle-orm";
import { db } from "../db/index.js";
import { rolePermissionTable, roleTable, userTable } from "../db/schema/users.js";

// ─── JWT config ──────────────────────────────────────────────────────────────
// 24h bearer tokens (issue #135). The secret comes from env; if it is missing
// or still the placeholder, we fail loudly at boot rather than silently issue
// trivially-forgeable tokens.
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_TTL = "24h";

function getSecret(): string {
  if (!JWT_SECRET || JWT_SECRET === "change-me-to-a-64-hex-char-random-secret") {
    throw new Error(
      "JWT_SECRET is not set (or still the placeholder). Set a random value in .env, " +
      "e.g. `openssl rand -hex 32`, then restart the backend (issue #135).",
    );
  }
  return JWT_SECRET;
}

export interface AuthTokenPayload {
  sub: number; // user id
  username: string;
  roleId: number;
  role: string;
  isAdmin: boolean;
  tenantId?: number; // tenant context (optional for backwards compatibility)
}

export function signToken(payload: AuthTokenPayload): string {
  return jwt.sign(payload, getSecret(), { expiresIn: JWT_TTL });
}

function verifyToken(token: string): AuthTokenPayload {
  const decoded = jwt.verify(token, getSecret()) as unknown as AuthTokenPayload;
  if (typeof decoded?.sub !== "number") throw new Error("invalid token payload");
  return decoded;
}

// ─── Express augmentation: req.auth ─────────────────────────────────────────
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      auth?: AuthTokenPayload;
    }
  }
}

export interface RolePermissionSet {
  role: string;
  roleId: number;
  isAdmin: boolean;
  permissions: string[]; // moduleIds this role can access
}

/** Load a user's role + route permissions from the DB. */
export async function loadRolePermissions(userId: number): Promise<RolePermissionSet | null> {
  const user = await db
    .select({
      roleId: userTable.roleId,
      roleName: roleTable.name,
      isAdmin: roleTable.isAdmin,
    })
    .from(userTable)
    .innerJoin(roleTable, eq(userTable.roleId, roleTable.id))
    .where(eq(userTable.id, userId))
    .limit(1);

  const row = user[0];
  if (!row) return null;
  if (row.isAdmin) {
    // Admin has every route — fail-closed, never needs rows in the matrix.
    return { role: row.roleName, roleId: row.roleId, isAdmin: true, permissions: ["*"] };
  }
  const perms = await db
    .select({ moduleId: rolePermissionTable.moduleId })
    .from(rolePermissionTable)
    .where(eq(rolePermissionTable.roleId, row.roleId));
  return {
    role: row.roleName,
    roleId: row.roleId,
    isAdmin: false,
    permissions: perms.map((p) => p.moduleId),
  };
}

// ─── Middleware ─────────────────────────────────────────────────────────────
/** Authenticates the bearer token. On success sets req.auth. On failure 401. */
export function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  const token = header?.startsWith("Bearer ") ? header.slice("Bearer ".length) : undefined;
  if (!token) {
    res.status(401).json({ error: "Authentication required" });
    return;
  }
  try {
    req.auth = verifyToken(token);
    next();
  } catch {
    res.status(401).json({ error: "Invalid or expired token" });
  }
}

/**
 * Route-level permission guard (issue #135). Call after requireAuth. The
 * moduleId matches the route keys the admin toggles in the permissions UI. The
 * admin role bypasses (has "*"). Denies with 403 — never 401 (we ARE
 * authenticated, just not allowed here).
 */
export function requirePermission(moduleId: string) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    if (!req.auth) {
      res.status(401).json({ error: "Authentication required" });
      return;
    }
    if (req.auth.isAdmin) {
      next();
      return;
    }
    const set = await loadRolePermissions(req.auth.sub);
    if (!set) {
      res.status(403).json({ error: "Account not found" });
      return;
    }
    if (set.permissions.includes(moduleId) || set.permissions.includes("*")) {
      next();
      return;
    }
    res.status(403).json({ error: `You do not have access to ${moduleId}` });
  };
}

/**
 * Route guard that passes when the role has ANY of the given modules.
 *
 * Some routes serve multiple modules (e.g. employee advances are both an
 * "employees" and a "payroll" concern — the frontend Advances page is guarded
 * by "payroll" while it calls the /employees/* backend routes). Requiring a
 * single module would 403 a role that legitimately holds the other one.
 */
export function requireAnyPermission(...moduleIds: string[]) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    if (!req.auth) {
      res.status(401).json({ error: "Authentication required" });
      return;
    }
    if (req.auth.isAdmin) {
      next();
      return;
    }
    const set = await loadRolePermissions(req.auth.sub);
    if (!set) {
      res.status(403).json({ error: "Account not found" });
      return;
    }
    if (
      set.permissions.includes("*") ||
      moduleIds.some((m) => set.permissions.includes(m))
    ) {
      next();
      return;
    }
    res.status(403).json({ error: `You do not have access to ${moduleIds.join(" or ")}` });
  };
}
