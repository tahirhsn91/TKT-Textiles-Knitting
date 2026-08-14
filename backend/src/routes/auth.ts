import { Router, type IRouter } from "express";
import { eq } from "drizzle-orm";
import argon2 from "argon2";
import { db } from "../db/index.js";
import { roleTable, userTable } from "../db/schema/users.js";
import { signToken, loadRolePermissions, requireAuth } from "../lib/auth.js";

const router: IRouter = Router();

/**
 * POST /api/auth/login — public. Validates username + password (argon2),
 * returns a 24h bearer JWT plus the user/role/permissions for session restore.
 */
router.post("/login", async (req, res): Promise<void> => {
  const { username, password } = req.body ?? {};
  if (typeof username !== "string" || typeof password !== "string" || !username || !password) {
    res.status(400).json({ error: "username and password are required" });
    return;
  }

  const rows = await db
    .select({
      id: userTable.id,
      username: userTable.username,
      displayName: userTable.displayName,
      passwordHash: userTable.passwordHash,
      isActive: userTable.isActive,
      employeeId: userTable.employeeId,
      roleId: userTable.roleId,
      roleName: roleTable.name,
      isAdmin: roleTable.isAdmin,
    })
    .from(userTable)
    .innerJoin(roleTable, eq(userTable.roleId, roleTable.id))
    .where(eq(userTable.username, username))
    .limit(1);

  const user = rows[0];
  // Same message whether the user doesn't exist or the password is wrong —
  // don't reveal which usernames are valid.
  if (!user || !user.isActive || !(await argon2.verify(user.passwordHash, password))) {
    res.status(401).json({ error: "Invalid username or password" });
    return;
  }

  const perms = await loadRolePermissions(user.id);
  const token = signToken({
    sub: user.id,
    username: user.username,
    roleId: user.roleId,
    role: user.roleName,
    isAdmin: user.isAdmin,
  });

  res.json({
    token,
    user: {
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      employeeId: user.employeeId,
    },
    role: { id: user.roleId, name: user.roleName, isAdmin: user.isAdmin },
    permissions: perms?.permissions ?? [],
  });
});

/**
 * GET /api/auth/me — authenticated. Returns the current user, role, and
 * permission set, used by the frontend to restore the session on boot.
 */
router.get("/me", requireAuth, async (req, res): Promise<void> => {
  const uid = req.auth!.sub;
  const rows = await db
    .select({
      id: userTable.id,
      username: userTable.username,
      displayName: userTable.displayName,
      employeeId: userTable.employeeId,
      roleId: userTable.roleId,
      roleName: roleTable.name,
      isAdmin: roleTable.isAdmin,
      isActive: userTable.isActive,
    })
    .from(userTable)
    .innerJoin(roleTable, eq(userTable.roleId, roleTable.id))
    .where(eq(userTable.id, uid))
    .limit(1);

  const user = rows[0];
  if (!user || !user.isActive) {
    res.status(401).json({ error: "Account not found or inactive" });
    return;
  }
  const perms = await loadRolePermissions(user.id);
  res.json({
    user: { id: user.id, username: user.username, displayName: user.displayName, employeeId: user.employeeId },
    role: { id: user.roleId, name: user.roleName, isAdmin: user.isAdmin },
    permissions: perms?.permissions ?? [],
  });
});

/**
 * PUT /api/auth/password — authenticated self-service password change.
 * Verifies the current password (argon2), then rehashes and stores the new one.
 * The existing bearer token stays valid — the user is not forced to re-login.
 */
router.put("/password", requireAuth, async (req, res): Promise<void> => {
  const uid = req.auth!.sub;
  const { currentPassword, newPassword } = req.body ?? {};

  if (typeof currentPassword !== "string" || !currentPassword) {
    res.status(400).json({ error: "currentPassword is required" });
    return;
  }
  if (typeof newPassword !== "string" || newPassword.length < 6) {
    res.status(400).json({ error: "newPassword must be at least 6 characters" });
    return;
  }
  if (newPassword === currentPassword) {
    res.status(400).json({ error: "New password must be different from the current password" });
    return;
  }

  const [user] = await db
    .select({ id: userTable.id, passwordHash: userTable.passwordHash })
    .from(userTable)
    .where(eq(userTable.id, uid))
    .limit(1);

  if (!user) {
    res.status(401).json({ error: "Account not found" });
    return;
  }
  if (!(await argon2.verify(user.passwordHash, currentPassword))) {
    res.status(400).json({ error: "Current password is incorrect" });
    return;
  }

  const hash = await argon2.hash(newPassword);
  await db
    .update(userTable)
    .set({ passwordHash: hash, updatedAt: new Date() })
    .where(eq(userTable.id, uid));

  res.json({ ok: true });
});

export default router;
