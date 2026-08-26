import {
  pgTable,
  serial,
  integer,
  numeric,
  date,
  text,
  timestamp,
  boolean,
  check,
  index,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { partyMasterTable, yarnTypeMasterTable } from "./lookups.js";
import { transactionHeaderTable } from "./transactions.js";
import { tenantTable } from "./tenants.js";

// ─── Daily Delivery ────────────────────────────────────────────────────────
// One row per fabric delivery: single line by product decision (Q1-A).
// Rolls are whole numbers; net weight is kg with 3 decimals, matching the
// rest of the app. SL is a free-text string (e.g. a lot/serial marker), GSM
// an optional number.
export const dailyDeliveryTable = pgTable("daily_delivery", {
    tenantId: integer("tenant_id").notNull().default(1).references(() => tenantTable.id, { onDelete: "cascade" }),
  id: serial("id").primaryKey(),
  deliveryDate: date("delivery_date").notNull(),
  partyId: integer("party_id")
    .notNull()
    .references(() => partyMasterTable.id),
  yarnTypeId: integer("yarn_type_id")
    .notNull()
    .references(() => yarnTypeMasterTable.id),
  challanNo: text("challan_no").notNull(),
  sl: text("sl"),
  gsm: integer("gsm"),
  quantity: integer("quantity").notNull(),
  netWeight: numeric("net_weight", { precision: 12, scale: 3 }).notNull(),
  status: text("status").notNull().default("submitted"),
  createdBy: text("created_by").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedBy: text("updated_by"),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),

  // ─── Consumption ─────────────────────────────────────────────────────────
  // Set when a Fabric Delivery transaction books this delivery. Permanent
  // lock, same semantics as yarn receipt / production reconciliation; the FK
  // survives the transaction's deletion (ON DELETE SET NULL) as an audit trail.
  reconciled: boolean("reconciled").notNull().default(false),
  reconciledTransactionId: integer("reconciled_transaction_id")
    .references(() => transactionHeaderTable.id, { onDelete: "set null" }),
  reconciledAt: timestamp("reconciled_at"),
}, (t) => [
  check("daily_delivery_status_check", sql`${t.status} IN ('submitted', 'cancelled')`),
  check("daily_delivery_quantity_check", sql`${t.quantity} > 0`),
  check("daily_delivery_net_weight_check", sql`${t.netWeight} > 0`),
  // Serves the "what is still available to book for this date + party" lookup
  // the transaction form fires on every type/date/party change.
  index("daily_delivery_reconcile_idx").on(
    t.deliveryDate, t.partyId, t.reconciled,
  ),
  // Serves the "Get deliveries by date" summary query directly.
  index("daily_delivery_date_idx").on(t.deliveryDate, t.partyId),
]);

export const insertDailyDeliverySchema = createInsertSchema(dailyDeliveryTable).omit({
  id: true,
  status: true,
  createdAt: true,
  updatedAt: true,
  reconciled: true,
  reconciledTransactionId: true,
  reconciledAt: true,
});
export type InsertDailyDelivery = z.infer<typeof insertDailyDeliverySchema>;
export type DailyDelivery = typeof dailyDeliveryTable.$inferSelect;
