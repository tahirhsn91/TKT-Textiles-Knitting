import {
  pgTable,
  serial,
  text,
  integer,
  boolean,
  timestamp,
  index,
} from "drizzle-orm/pg-core";
import { tenantTable } from "./tenants.js";
import { userTable } from "./users.js";

/**
 * User invitations (issue #219 1.4).
 * A super-admin / tenant admin invites a person (by email) to a tenant role.
 * The invite carries a token used to accept it (in a real deployment an email
 * is sent; in this env the acceptance can be triggered via the API/dev flow).
 */
export const userInvitationsTable = pgTable(
  "user_invitations",
  {
    id: serial("id").primaryKey(),
    tenantId: integer("tenant_id")
      .notNull()
      .references(() => tenantTable.id, { onDelete: "cascade" }),
    invitedBy: integer("invited_by").references(() => userTable.id, {
      onDelete: "set null",
    }),
    email: text("email").notNull(),
    // The role name the invitee will receive (Admin / Manager / Supervisor).
    role: text("role").notNull().default("Manager"),
    token: text("token").notNull(),
    // pending / accepted / revoked / expired
    status: text("status").notNull().default("pending"),
    acceptedBy: integer("accepted_by").references(() => userTable.id, {
      onDelete: "set null",
    }),
    acceptedAt: timestamp("accepted_at", { mode: "string" }),
    expiresAt: timestamp("expires_at", { mode: "string" }),
    createdAt: timestamp("created_at", { mode: "string" }).defaultNow(),
    updatedAt: timestamp("updated_at", { mode: "string" }).defaultNow(),
  },
  (t) => [
    index("idx_invitations_tenant").on(t.tenantId),
    index("idx_invitations_status").on(t.status),
  ],
);

export type UserInvitation = typeof userInvitationsTable.$inferSelect;
export type InsertUserInvitation = typeof userInvitationsTable.$inferInsert;
