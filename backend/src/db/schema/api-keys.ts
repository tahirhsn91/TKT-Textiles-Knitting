import { pgTable, serial, integer, varchar, timestamp, text } from "drizzle-orm/pg-core";
import { tenantTable } from "./tenants.js";

/**
 * api_keys — tenant-scoped API keys for programmatic access (issue #219 2.4).
 * Each key belongs to a tenant, has a human label, a hashed secret, an optional
 * expiry, and can be revoked. The plaintext key is shown only once at creation.
 */
export const apiKeyTable = pgTable("api_keys", {
  id: serial("id").primaryKey(),
  tenantId: integer("tenant_id")
    .notNull()
    .references(() => tenantTable.id, { onDelete: "cascade" }),
  label: varchar("label", { length: 120 }).notNull(),
  // Hash (sha256) of the raw key; the raw key is never stored in plaintext.
  keyHash: varchar("key_hash", { length: 128 }).notNull(),
  // Last 8 chars of the raw key, for display/identification in the UI.
  keyHint: varchar("key_hint", { length: 16 }).notNull(),
  lastUsedAt: timestamp("last_used_at", { withTimezone: true }),
  expiresAt: timestamp("expires_at", { withTimezone: true }),
  revokedAt: timestamp("revoked_at", { withTimezone: true }),
  createdBy: integer("created_by"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});
