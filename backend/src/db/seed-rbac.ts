/**
 * Seed: initial RBAC data (issue #135). Idempotent — safe to run repeatedly.
 *
 * Seeds:
 *   - Roles: Admin, Manager, Supervisor (already seeded by migration 0015;
 *     this ensures they exist regardless).
 *   - Default route permissions for Manager / Supervisor (sensible defaults).
 *   - The first Admin user: username "admin", password "tkttextiles12#",
 *     no employee link, active.
 *
 * Run: npm run db:seed
 */
import argon2 from "argon2";
import { eq } from "drizzle-orm";
import { db } from "./index.js";
import { roleTable, rolePermissionTable, userTable } from "./schema/users.js";
import { logger } from "../lib/logger.js";

const SEED_ADMIN_USERNAME = process.env.SEED_ADMIN_USERNAME ?? "admin";
const SEED_ADMIN_PASSWORD = process.env.SEED_ADMIN_PASSWORD ?? "tkttextiles12#";

// Sensible v1 defaults (issue #135). Admin is handled implicitly (is_admin → all
// routes, no rows needed). Manager/Supervisor start with these; admin edits.
const DEFAULT_PERMISSIONS: Record<string, string[]> = {
  Manager: [
    "dashboard",
    "transactions",
    "dailyProduction",
    "yarnReceipts",
    "dailyDeliveries",
    "payroll",
    "reports",
    "maintenance",
  ],
  Supervisor: ["dashboard", "dailyProduction", "yarnReceipts", "dailyDeliveries", "maintenance"],
};

async function seedRoles(): Promise<Map<string, number>> {
  const names = ["Admin", "Manager", "Supervisor"] as const;
  const idByName = new Map<string, number>();
  for (const name of names) {
    const isAdmin = name === "Admin";
    const [existing] = await db.select().from(roleTable).where(eq(roleTable.name, name)).limit(1);
    let id: number;
    if (existing) {
      id = existing.id;
      if (existing.isAdmin !== isAdmin) {
        await db.update(roleTable).set({ isAdmin }).where(eq(roleTable.id, existing.id));
      }
    } else {
      const [row] = await db
        .insert(roleTable)
        .values({ name, isAdmin })
        .returning();
      id = row.id;
      logger.info({ role: name }, "seeded role");
    }
    idByName.set(name, id);
  }
  return idByName;
}

async function seedPermissions(roleIds: Map<string, number>): Promise<void> {
  for (const [roleName, modules] of Object.entries(DEFAULT_PERMISSIONS)) {
    const roleId = roleIds.get(roleName);
    if (!roleId) continue;
    // Only add missing rows — never revoke an admin's manual grant on re-run.
    const existing = await db
      .select()
      .from(rolePermissionTable)
      .where(eq(rolePermissionTable.roleId, roleId));
    const existingSet = new Set(existing.map((p) => p.moduleId));
    const toAdd = modules.filter((m) => !existingSet.has(m));
    if (toAdd.length > 0) {
      await db
        .insert(rolePermissionTable)
        .values(toAdd.map((moduleId) => ({ roleId, moduleId })));
      logger.info({ role: roleName, count: toAdd.length }, "seeded role permissions");
    }
  }
}

async function seedAdmin(roleIds: Map<string, number>): Promise<void> {
  const adminId = roleIds.get("Admin");
  if (!adminId) throw new Error("Admin role missing");
  const existing = await db
    .select()
    .from(userTable)
    .where(eq(userTable.username, SEED_ADMIN_USERNAME))
    .limit(1);
  if (existing.length > 0) {
    logger.info({ username: SEED_ADMIN_USERNAME }, "admin already exists — skipping");
    return;
  }
  const hash = await argon2.hash(SEED_ADMIN_PASSWORD);
  await db.insert(userTable).values({
    username: SEED_ADMIN_USERNAME,
    displayName: "Administrator",
    passwordHash: hash,
    roleId: adminId,
    employeeId: null,
    isActive: true,
  });
  logger.info({ username: SEED_ADMIN_USERNAME }, "seeded admin user");
}

async function main(): Promise<void> {
  logger.info("running RBAC seed");
  const roleIds = await seedRoles();
  await seedPermissions(roleIds);
  await seedAdmin(roleIds);
  logger.info("RBAC seed complete");
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    logger.error({ err }, "RBAC seed failed");
    process.exit(1);
  });
