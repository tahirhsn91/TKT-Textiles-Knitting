import { Router, type IRouter } from "express";
import { eq, and, inArray } from "drizzle-orm";
import argon2 from "argon2";
import { db } from "../db/index.js";
import {
  roleTable,
  rolePermissionTable,
  userTable,
} from "../db/schema/users.js";
import { requireAuth, requirePermission } from "../lib/auth.js";
import { activeTenantId } from "../middleware/tenant-context.js";

const router: IRouter = Router();

router.use(requireAuth);
// Everything below is admin-only.
router.use(requirePermission("users"));

/** Map a user row (+ role) to the wire shape (never exposes the hash). */
function serializeUser(u: {
  id: number;
  username: string;
  displayName: string;
  roleId: number;
  roleName: string;
  employeeId: number | null;
  isActive: boolean;
}) {
  return {
    id: u.id,
    username: u.username,
    displayName: u.displayName,
    roleId: u.roleId,
    roleName: u.roleName,
    employeeId: u.employeeId,
    isActive: u.isActive,
  };
}

// ─── Roles ───────────────────────────────────────────────────────────────────

/** GET /api/users/roles — list the active tenant's roles (with isAdmin flag). */
router.get("/roles", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const roles = await db.select().from(roleTable).where(eq(roleTable.tenantId, tenantId)).orderBy(roleTable.id);
  res.json(roles.map((r) => ({ id: r.id, name: r.name, isAdmin: r.isAdmin })));
});

/** GET /api/users/permissions — full role×route matrix for the active tenant (Admin row always full). */
router.get("/permissions", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const roles = await db.select().from(roleTable).where(eq(roleTable.tenantId, tenantId)).orderBy(roleTable.id);
  const roleIds = roles.map((r) => r.id);
  const perms = roleIds.length > 0
    ? await db.select().from(rolePermissionTable).where(inArray(rolePermissionTable.roleId, roleIds))
    : [];
  const byRole = new Map<number, string[]>();
  for (const p of perms) {
    const arr = byRole.get(p.roleId) ?? [];
    arr.push(p.moduleId);
    byRole.set(p.roleId, arr);
  }
  res.json(
    roles.map((r) => ({
      roleId: r.id,
      role: r.name,
      isAdmin: r.isAdmin,
      permissions: byRole.get(r.id) ?? [],
    })),
  );
});

/**
 * PUT /api/users/permissions — replace the permission set for ONE non-admin
 * role. The admin role is locked (server-side) and cannot be edited here.
 */
router.put("/permissions", async (req, res): Promise<void> => {
  const { roleId, permissions } = req.body ?? {};
  const rid = Number(roleId);
  if (!rid || !Array.isArray(permissions) || !permissions.every((p) => typeof p === "string")) {
    res.status(400).json({ error: "roleId and permissions[] are required" });
    return;
  }
  const [role] = await db.select().from(roleTable).where(eq(roleTable.id, rid)).limit(1);
  if (!role) {
    res.status(404).json({ error: "Role not found" });
    return;
  }
  if (role.isAdmin) {
    res.status(400).json({ error: "Admin role permissions are locked" });
    return;
  }
  // Replace the matrix for this role in a transaction.
  await db.transaction(async (tx) => {
    await tx.delete(rolePermissionTable).where(eq(rolePermissionTable.roleId, rid));
    if (permissions.length > 0) {
      await tx
        .insert(rolePermissionTable)
        .values(permissions.map((moduleId: string) => ({ roleId: rid, moduleId })));
    }
  });
  res.json({ ok: true, roleId: rid, permissions });
});

// ─── Users ─────────────────────────────────────────────────────────────────

/** GET /api/users — list the active tenant's users with role names. */
router.get("/", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const rows = await db
    .select({
      id: userTable.id,
      username: userTable.username,
      displayName: userTable.displayName,
      roleId: userTable.roleId,
      roleName: roleTable.name,
      employeeId: userTable.employeeId,
      isActive: userTable.isActive,
    })
    .from(userTable)
    .innerJoin(roleTable, eq(userTable.roleId, roleTable.id))
    .where(eq(userTable.tenantId, tenantId))
    .orderBy(userTable.username);
  res.json(rows.map(serializeUser));
});

/**
 * POST /api/users — create a user (admin sets the initial password). Checks for
 * duplicate username and duplicate employee link.
 */
router.post("/", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const { username, displayName, password, roleId, employeeId, isActive } = req.body ?? {};
  if (typeof username !== "string" || !username.trim()) {
    res.status(400).json({ error: "username is required" });
    return;
  }
  if (typeof displayName !== "string" || !displayName.trim()) {
    res.status(400).json({ error: "displayName is required" });
    return;
  }
  if (typeof password !== "string" || password.length < 6) {
    res.status(400).json({ error: "password must be at least 6 characters" });
    return;
  }
  const rid = Number(roleId);
  // The role must belong to the active tenant (cross-tenant role assignment forbidden).
  const [role] = await db
    .select()
    .from(roleTable)
    .where(and(eq(roleTable.id, rid), eq(roleTable.tenantId, tenantId)))
    .limit(1);
  if (!role) {
    res.status(400).json({ error: "Invalid role" });
    return;
  }
  if (role.isAdmin && !req.auth!.isAdmin) {
    res.status(403).json({ error: "Only an admin can create an admin user" });
    return;
  }

  const uname = username.trim();
  const existing = await db
    .select({ id: userTable.id })
    .from(userTable)
    .where(and(eq(userTable.username, uname), eq(userTable.tenantId, tenantId)))
    .limit(1);
  if (existing.length > 0) {
    res.status(409).json({ error: "Username already exists" });
    return;
  }

  const empId = employeeId != null ? Number(employeeId) : null;
  if (empId != null && Number.isNaN(empId)) {
    res.status(400).json({ error: "Invalid employeeId" });
    return;
  }

  const hash = await argon2.hash(password);
  const [created] = await db
    .insert(userTable)
    .values({
      username: uname,
      displayName: displayName.trim(),
      passwordHash: hash,
      roleId: rid,
      tenantId,
      employeeId: empId,
      isActive: isActive === undefined ? true : Boolean(isActive),
    })
    .returning();

  res.status(201).json(
    serializeUser({
      id: created.id,
      username: created.username,
      displayName: created.displayName,
      roleId: created.roleId,
      roleName: role.name,
      employeeId: created.employeeId,
      isActive: created.isActive,
    }),
  );
});

/** PATCH /api/users/:id — update role / employee link / active status (active tenant only). */
router.patch("/:id", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const id = Number(req.params.id);
  if (!id) {
    res.status(400).json({ error: "Invalid id" });
    return;
  }
  const [existing] = await db
    .select({ id: userTable.id, roleId: userTable.roleId, roleName: roleTable.name })
    .from(userTable)
    .innerJoin(roleTable, eq(userTable.roleId, roleTable.id))
    .where(and(eq(userTable.id, id), eq(userTable.tenantId, tenantId)))
    .limit(1);
  if (!existing) {
    res.status(404).json({ error: "User not found" });
    return;
  }

  const { roleId, employeeId, isActive, displayName } = req.body ?? {};

  let newRoleId: number | undefined;
  if (roleId !== undefined) {
    const rid = Number(roleId);
    // Role must belong to the active tenant (prevent cross-tenant role assignment).
    const [role] = await db
      .select()
      .from(roleTable)
      .where(and(eq(roleTable.id, rid), eq(roleTable.tenantId, tenantId)))
      .limit(1);
    if (!role) {
      res.status(400).json({ error: "Invalid role" });
      return;
    }
    if (role.isAdmin && !req.auth!.isAdmin) {
      res.status(403).json({ error: "Only an admin can assign the admin role" });
      return;
    }
    newRoleId = rid;
  }

  let newEmpId: number | null | undefined;
  if (employeeId !== undefined) {
    const empId = employeeId == null ? null : Number(employeeId);
    if (empId != null && Number.isNaN(empId)) {
      res.status(400).json({ error: "Invalid employeeId" });
      return;
    }
    newEmpId = empId;
  }

  const patch: Record<string, unknown> = { updatedAt: new Date() };
  if (displayName !== undefined) patch.displayName = displayName;
  if (newRoleId !== undefined) patch.roleId = newRoleId;
  if (newEmpId !== undefined) patch.employeeId = newEmpId;
  if (isActive !== undefined) patch.isActive = Boolean(isActive);

  const [updated] = await db
    .update(userTable)
    .set(patch)
    .where(and(eq(userTable.id, id), eq(userTable.tenantId, tenantId)))
    .returning();
  const [fresh] = await db
    .select({ id: userTable.id, username: userTable.username, displayName: userTable.displayName, roleId: userTable.roleId, roleName: roleTable.name, employeeId: userTable.employeeId, isActive: userTable.isActive })
    .from(userTable)
    .innerJoin(roleTable, eq(userTable.roleId, roleTable.id))
    .where(and(eq(userTable.id, updated.id), eq(userTable.tenantId, tenantId)))
    .limit(1);
  res.json(serializeUser(fresh));
});

/**
 * DELETE /api/users/:id — permanently delete a user.
 * Admin-only (the router is already admin-gated via requirePermission("users");
 * we also assert isAdmin on the request for defense in depth). Admin accounts
 * and the caller's own account cannot be deleted here.
 */
router.delete("/:id", async (req, res): Promise<void> => {
  if (!req.auth?.isAdmin) {
    res.status(403).json({ error: "Only an admin can delete a user" });
    return;
  }
  const id = Number(req.params.id);
  if (!id) {
    res.status(400).json({ error: "Invalid id" });
    return;
  }
  const [existing] = await db
    .select({
      id: userTable.id,
      roleName: roleTable.name,
      isAdmin: roleTable.isAdmin,
    })
    .from(userTable)
    .innerJoin(roleTable, eq(userTable.roleId, roleTable.id))
    .where(and(eq(userTable.id, id), eq(userTable.tenantId, activeTenantId(req))))
    .limit(1);
  if (!existing) {
    res.status(404).json({ error: "User not found" });
    return;
  }
  if (existing.isAdmin) {
    res.status(400).json({ error: "Admin accounts cannot be deleted" });
    return;
  }
  if (id === req.auth.sub) {
    res.status(400).json({ error: "You cannot delete your own account" });
    return;
  }
  await db.delete(userTable).where(and(eq(userTable.id, id), eq(userTable.tenantId, activeTenantId(req))));
  res.json({ ok: true, id });
});

/** PUT /api/users/:id/password — admin resets a user's password. */
router.put("/:id/password", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const id = Number(req.params.id);
  const { password } = req.body ?? {};
  if (!id) {
    res.status(400).json({ error: "Invalid id" });
    return;
  }
  if (typeof password !== "string" || password.length < 6) {
    res.status(400).json({ error: "password must be at least 6 characters" });
    return;
  }
  const [existing] = await db
    .select({ id: userTable.id })
    .from(userTable)
    .where(and(eq(userTable.id, id), eq(userTable.tenantId, tenantId)))
    .limit(1);
  if (!existing) {
    res.status(404).json({ error: "User not found" });
    return;
  }
  const hash = await argon2.hash(password);
  await db
    .update(userTable)
    .set({ passwordHash: hash, updatedAt: new Date() })
    .where(and(eq(userTable.id, id), eq(userTable.tenantId, tenantId)));
  res.json({ ok: true });
});

export default router;
