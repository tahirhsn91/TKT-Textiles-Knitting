import { Router, type IRouter } from "express";
import { randomBytes } from "node:crypto";
import { eq, and } from "drizzle-orm";
import argon2 from "argon2";
import { db } from "../db/index.js";
import { activeTenantId } from "../middleware/tenant-context.js";
import { userInvitationsTable } from "../db/schema/user-invitations.js";
import { userTable, roleTable } from "../db/schema/users.js";
import { auditLogTable } from "../db/schema/audit-log.js";
import { requireAuth, requirePermission } from "../lib/auth.js";

const router: IRouter = Router();
router.use(requireAuth);
// Only users-admins (tenant Admin or super-admin) manage invitations.
router.use(requirePermission("users"));

const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

function newToken(): string {
  return randomBytes(24).toString("hex");
}

/**
 * GET /api/invitations — list the active tenant's invitations.
 */
router.get("/", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const rows = await db
    .select()
    .from(userInvitationsTable)
    .where(eq(userInvitationsTable.tenantId, tenantId))
    .orderBy(userInvitationsTable.createdAt);
  res.json(
    rows.map((r) => ({
      id: r.id,
      email: r.email,
      role: r.role,
      status: r.status,
      token: r.token,
      expires_at: r.expiresAt,
      created_at: r.createdAt,
    })),
  );
});

/**
 * POST /api/invitations — invite a person to the active tenant (by email + role).
 * Generates a token; no email is sent in this env (no mail service) — the token
 * is returned for the dev flow / acceptance.
 */
router.post("/", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const { email, role } = req.body ?? {};
  if (typeof email !== "string" || !email.trim() || !email.includes("@")) {
    res.status(400).json({ error: "A valid email is required" });
    return;
  }
  const roleName = (typeof role === "string" && ["Admin", "Manager", "Supervisor"].includes(role)) ? role : "Manager";
  // Ensure the role exists for this tenant.
  const [roleRow] = await db
    .select({ id: roleTable.id })
    .from(roleTable)
    .where(and(eq(roleTable.name, roleName), eq(roleTable.tenantId, tenantId)))
    .limit(1);
  if (!roleRow) {
    res.status(400).json({ error: `Role '${roleName}' not found for tenant` });
    return;
  }
  // Reject if this email already has an active invite or a user in this tenant.
  const existingInvite = await db
    .select({ id: userInvitationsTable.id })
    .from(userInvitationsTable)
    .where(and(eq(userInvitationsTable.tenantId, tenantId), eq(userInvitationsTable.email, email.trim().toLowerCase()), eq(userInvitationsTable.status, "pending")))
    .limit(1);
  if (existingInvite.length > 0) {
    res.status(409).json({ error: "An active invite already exists for this email" });
    return;
  }
  const token = newToken();
  const [invite] = await db
    .insert(userInvitationsTable)
    .values({
      tenantId,
      invitedBy: req.auth!.sub,
      email: email.trim().toLowerCase(),
      role: roleName,
      token,
      status: "pending",
      expiresAt: new Date(Date.now() + INVITE_TTL_MS).toISOString(),
    })
    .returning();

  await db.insert(auditLogTable).values({
    actorUserId: req.auth!.sub,
    targetTenantId: tenantId,
    action: "invite.create",
    entityType: "user_invitation",
    entityId: invite.id,
    description: `Invited ${invite.email} as ${roleName}`,
  });

  res.status(201).json({
    id: invite.id,
    email: invite.email,
    role: invite.role,
    status: invite.status,
    token: invite.token,
    expires_at: invite.expiresAt,
  });
});

/**
 * POST /api/invitations/:token/revoke — revoke a pending invite.
 */
router.post("/:token/revoke", async (req, res): Promise<void> => {
  const tenantId = activeTenantId(req);
  const token = String(req.params.token);
  const [updated] = await db
    .update(userInvitationsTable)
    .set({ status: "revoked", updatedAt: new Date().toISOString() })
    .where(and(eq(userInvitationsTable.token, token), eq(userInvitationsTable.tenantId, tenantId)))
    .returning({ id: userInvitationsTable.id, email: userInvitationsTable.email });
  if (!updated) {
    res.status(404).json({ error: "Invitation not found" });
    return;
  }
  res.json({ ok: true, id: updated.id });
});

/**
 * POST /api/invitations/:token/accept — accept an invite and create the user.
 * Sets a default temp password (in a full deployment the user sets it via a
 * password-reset/acceptance email; here we provide it in the response for the
 * dev flow).
 */
router.post("/:token/accept", async (req, res): Promise<void> => {
  const { token } = req.params as { token: string };

  const [invite] = await db
    .select()
    .from(userInvitationsTable)
    .where(eq(userInvitationsTable.token, token))
    .limit(1);
  if (!invite) {
    res.status(404).json({ error: "Invitation not found" });
    return;
  }
  if (invite.status !== "pending") {
    res.status(409).json({ error: `Invitation is ${invite.status}` });
    return;
  }
  if (invite.expiresAt && new Date(invite.expiresAt).getTime() < Date.now()) {
    await db
      .update(userInvitationsTable)
      .set({ status: "expired", updatedAt: new Date().toISOString() })
      .where(eq(userInvitationsTable.id, invite.id));
    res.status(410).json({ error: "Invitation has expired" });
    return;
  }

  // Reject if a user with this email already exists in the tenant.
  const existingUser = await db
    .select({ id: userTable.id })
    .from(userTable)
    .where(and(eq(userTable.username, invite.email), eq(userTable.tenantId, invite.tenantId)))
    .limit(1);
  if (existingUser.length > 0) {
    res.status(409).json({ error: "A user already exists for this email in the tenant" });
    return;
  }

  const [roleRow] = await db
    .select({ id: roleTable.id })
    .from(roleTable)
    .where(and(eq(roleTable.name, invite.role), eq(roleTable.tenantId, invite.tenantId)))
    .limit(1);
  if (!roleRow) {
    res.status(400).json({ error: `Role '${invite.role}' not configured for this tenant` });
    return;
  }

  const tempPassword = `New${randomBytes(4).toString("hex")}!`;
  const hash = await argon2.hash(tempPassword);
  const [created] = await db
    .insert(userTable)
    .values({
      username: invite.email,
      displayName: invite.email,
      passwordHash: hash,
      roleId: roleRow.id,
      tenantId: invite.tenantId,
      isActive: true,
    })
    .returning({ id: userTable.id, username: userTable.username });

  await db
    .update(userInvitationsTable)
    .set({ status: "accepted", acceptedBy: created.id, acceptedAt: new Date().toISOString(), updatedAt: new Date().toISOString() })
    .where(eq(userInvitationsTable.id, invite.id));

  await db.insert(auditLogTable).values({
    actorUserId: created.id,
    targetTenantId: invite.tenantId,
    action: "invite.accept",
    entityType: "user",
    entityId: created.id,
    description: `Invitation accepted; user "${invite.email}" created as ${invite.role}`,
  });

  res.json({
    ok: true,
    user_id: created.id,
    username: created.username,
    temp_password: tempPassword,
  });
});

export default router;
