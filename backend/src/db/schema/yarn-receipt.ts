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
import { partyMasterTable, yarnCountMasterTable, yarnBrandMasterTable } from "./lookups.js";
import { transactionHeaderTable } from "./transactions.js";
import { tenantTable } from "./tenants.js";

// ─── Yarn Receipt Header ───────────────────────────────────────────────────
// One row per yarn delivery from a party. Lines live in
// yarn_receipt_detail, one per (yarn type, yarn count) lot.
//
// Free editing by design (requirement Q5-A): no reconciliation/locking
// fields for now. `status` mirrors the production soft-delete convention
// ("cancelled" preserves the audit trail instead of hard DELETE), even
// though nothing downstream consumes receipts yet.
export const yarnReceiptHeaderTable = pgTable("yarn_receipt_header", {
    tenantId: integer("tenant_id").notNull().default(1).references(() => tenantTable.id, { onDelete: "cascade" }),
  id: serial("id").primaryKey(),
  docNumber: text("doc_number").notNull(),
  receiptDate: date("receipt_date").notNull(),
  partyId: integer("party_id")
    .notNull()
    .references(() => partyMasterTable.id),
  status: text("status").notNull().default("submitted"),
  createdBy: text("created_by").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedBy: text("updated_by"),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),

  // ─── Consumption ─────────────────────────────────────────────────────────
  // Set when a Yarn Receipt transaction books this receipt. Same permanent
  // lock semantics as daily production reconciliation: once consumed, the
  // receipt can't be pulled into another transaction, and the FK survives
  // the transaction's deletion (ON DELETE SET NULL) as an audit trail.
  reconciled: boolean("reconciled").notNull().default(false),
  reconciledTransactionId: integer("reconciled_transaction_id")
    .references(() => transactionHeaderTable.id, { onDelete: "set null" }),
  reconciledAt: timestamp("reconciled_at"),
}, (t) => [
  check("yarn_receipt_header_status_check", sql`${t.status} IN ('submitted', 'cancelled')`),
  // Serves the "what receipts are still available to book for this date +
  // party" lookup the transaction form fires on every type/date/party change.
  index("yarn_receipt_header_reconcile_idx").on(
    t.receiptDate, t.partyId, t.reconciled,
  ),
  // Serves the "Get receipts by date" summary query directly.
  index("yarn_receipt_header_date_idx").on(t.receiptDate, t.partyId),
]);

export const insertYarnReceiptHeaderSchema = createInsertSchema(yarnReceiptHeaderTable).omit({
  id: true,
  status: true,
  createdAt: true,
  updatedAt: true,
  reconciled: true,
  reconciledTransactionId: true,
  reconciledAt: true,
});
export type InsertYarnReceiptHeader = z.infer<typeof insertYarnReceiptHeaderSchema>;
export type YarnReceiptHeader = typeof yarnReceiptHeaderTable.$inferSelect;

// ─── Yarn Receipt Detail ───────────────────────────────────────────────────
// One line per yarn lot: which yarn count + brand, how many bags, and the
// net weight of those bags. Quantity is whole bags (requirement Q10-A); net
// weight is kg with 3 decimals, matching the rest of the app.
export const yarnReceiptDetailTable = pgTable("yarn_receipt_detail", {
    tenantId: integer("tenant_id").notNull().default(1).references(() => tenantTable.id, { onDelete: "cascade" }),
  id: serial("id").primaryKey(),
  headerId: integer("header_id")
    .notNull()
    .references(() => yarnReceiptHeaderTable.id, { onDelete: "cascade" }),
  yarnCountId: integer("yarn_count_id")
    .notNull()
    .references(() => yarnCountMasterTable.id),
  yarnBrandId: integer("yarn_brand_id")
    .notNull()
    .references(() => yarnBrandMasterTable.id),
  quantity: integer("quantity").notNull(),
  netWeight: numeric("net_weight", { precision: 12, scale: 3 }).notNull(),
}, (t) => [
  check("yarn_receipt_detail_quantity_check", sql`${t.quantity} > 0`),
  check("yarn_receipt_detail_net_weight_check", sql`${t.netWeight} > 0`),
  // FK column — Postgres doesn't auto-index it; serves the header→lines
  // lookups (list/analytics/update/delete).
  index("yarn_receipt_detail_header_idx").on(t.headerId),
]);

export const insertYarnReceiptDetailSchema = createInsertSchema(yarnReceiptDetailTable).omit({
  id: true,
  headerId: true,
});
export type InsertYarnReceiptDetail = z.infer<typeof insertYarnReceiptDetailSchema>;
export type YarnReceiptDetail = typeof yarnReceiptDetailTable.$inferSelect;
