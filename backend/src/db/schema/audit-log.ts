import {
  pgTable,
  serial,
  integer,
  text,
  timestamp,
  jsonb,
  index,
  varchar,
} from "drizzle-orm/pg-core";
import { tenantTable } from "./tenants.js";
import { userTable } from "./users.js";

// ─── Audit log ──────────────────────────────────────────────────────────────
// Purpose-built audit trail for sensitive platform + tenant operations
// (Q9c): tenant creation/modification/activation/deactivation, super-admin
// tenant switching, cross-tenant admin operations, permission changes, and
// user management. Captures actor, actor tenant, target tenant, action,
// entity, before/after state, and request metadata.
export const auditLogTable = pgTable(
  "audit_log",
  {
    id: serial("id").primaryKey(),
    // Who performed the action.
    actorUserId: integer("actor_user_id").references(() => userTable.id, {
      onDelete: "set null",
    }),
    actorTenantId: integer("actor_tenant_id").references(() => tenantTable.id, {
      onDelete: "set null",
    }),
    // Which tenant the action targeted (may differ from the actor's own).
    targetTenantId: integer("target_tenant_id").references(() => tenantTable.id, {
      onDelete: "set null",
    }),
    // e.g. "tenant.create", "tenant.deactivate", "tenant.switch",
    // "permission.change", "user.manage", "cross-tenant.admin.op"
    action: varchar("action", { length: 100 }).notNull(),
    // The type of entity affected, e.g. "tenant", "user", "role", "config".
    entityType: varchar("entity_type", { length: 100 }),
    entityId: integer("entity_id"),
    // Human-readable summary.
    description: text("description"),
    // Snapshot of the relevant state before/after the change, if applicable.
    beforeJson: jsonb("before_json"),
    afterJson: jsonb("after_json"),
    ipAddress: varchar("ip_address", { length: 45 }),
    userAgent: text("user_agent"),
    createdAt: timestamp("created_at", { mode: "string" }).defaultNow(),
  },
  (t) => [
    index("idx_audit_log_actor").on(t.actorUserId),
    index("idx_audit_log_target_tenant").on(t.targetTenantId),
    index("idx_audit_log_action").on(t.action),
    index("idx_audit_log_created").on(t.createdAt),
  ],
);

export type AuditLog = typeof auditLogTable.$inferSelect;
export type InsertAuditLog = typeof auditLogTable.$inferInsert;
