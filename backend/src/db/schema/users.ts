import {
  pgTable,
  serial,
  text,
  integer,
  boolean,
  timestamp,
  uniqueIndex,
  index,
  primaryKey,
} from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { employeeMasterTable } from "./lookups.js";

// ─── Roles ──────────────────────────────────────────────────────────────────
// Fixed/seeded role set (Admin, Manager, Supervisor). Role *names* are not
// admin-editable in v1 (issue #135); only per-role route permissions change.
export const roleTable = pgTable(
  "role",
  {
    id: serial("id").primaryKey(),
    name: text("name").notNull().unique(),
    // Routes are locked to the admin role; this flag lets the permission
    // matrix render it non-editable and fail-closed by default.
    isAdmin: boolean("is_admin").notNull().default(false),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (t) => [uniqueIndex("role_name_idx").on(t.name)],
);

// ─── Route-level permissions per role ───────────────────────────────────────
// A single row per (role, moduleId). "moduleId" is the route/feature key the
// backend requirePermission(moduleId) middleware checks and the same list the
// admin UI toggles. Route-level boolean only (issue #135).
export const rolePermissionTable = pgTable(
  "role_permission",
  {
    roleId: integer("role_id")
      .notNull()
      .references(() => roleTable.id, { onDelete: "cascade" }),
    moduleId: text("module_id").notNull(),
  },
  (t) => [
    primaryKey({ columns: [t.roleId, t.moduleId] }),
    index("role_permission_role_idx").on(t.roleId),
  ],
);

// ─── Users ──────────────────────────────────────────────────────────────────
// A user authenticates with a username + password (argon2 hashed). Each user
// has exactly one role. A user may optionally be linked to an employee (via a
// nullable employee_id FK) — not every user is an employee (issue #135).
// Named app_user (not "user") to avoid a naming conflict with Postgres's
// built-in polymorphic "user" type when drizzle generates migrations.
export const userTable = pgTable(
  "app_user",
  {
    id: serial("id").primaryKey(),
    username: text("username").notNull(),
    displayName: text("display_name").notNull(),
    passwordHash: text("password_hash").notNull(),
    roleId: integer("role_id")
      .notNull()
      .references(() => roleTable.id),
    // Optional link to an employee record; NULL when the user is not an employee.
    employeeId: integer("employee_id").references(() => employeeMasterTable.id),
    isActive: boolean("is_active").notNull().default(true),
    tenantId: integer("tenant_id").notNull().default(1),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [uniqueIndex("user_username_idx").on(t.username)],
);

export const insertRoleSchema = createInsertSchema(roleTable).omit({ id: true, createdAt: true });
export type InsertRole = z.infer<typeof insertRoleSchema>;
export type Role = typeof roleTable.$inferSelect;

export const insertUserSchema = createInsertSchema(userTable).omit({
  id: true,
  passwordHash: true,
  createdAt: true,
  updatedAt: true,
});
export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof userTable.$inferSelect;
