import {
  pgTable,
  serial,
  text,
  integer,
  numeric,
  date,
  timestamp,
  boolean,
  jsonb,
  index,
  unique,
} from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { partyMasterTable, yarnTypeMasterTable, yarnCountMasterTable } from "./lookups.js";
import { companyInfoMasterTable } from "./company-info.js";
import { transactionHeaderTable } from "./transactions.js";

// ─── FBR Digital Invoicing ──────────────────────────────────────────────────
// An FBR invoice is generated from Fabric_Dispatch transactions. Lifecycle:
//   draft  -> generated locally; editable + deletable. Deleting un-marks its
//             transactions (via invoice_transaction junction) so they can be
//             re-invoiced. May hold a rejected-FBR raw response.
//   posted -> sent to FBR and accepted; terminal/read-only (no edit/delete/
//             repost). Corrections would need an FBR credit/debit note (out
//             of scope for v1).
//
// One invoice per party: aggregates all not-yet-invoiced Fabric_Dispatch
// transactions for that party across all dates, grouped by (party, yarn type,
// yarn count); sum(net weight) becomes the item quantity. The user manually
// enters a per-KG rate at generation; sales tax is a fixed 18%; total =
// value + tax.

export const invoiceTable = pgTable("invoice", {
  id: serial("id").primaryKey(),
  // invoiceDate = the generation date (today). Used as FBR invoiceDate.
  invoiceDate: date("invoice_date").notNull(),
  companyId: integer("company_id")
    .notNull()
    .references(() => companyInfoMasterTable.id),
  partyId: integer("party_id")
    .notNull()
    .references(() => partyMasterTable.id),
  // draft | posted
  status: text("status").notNull().default("draft"),
  // How this invoice was posted: 'fbr' (via FBR), 'local' (unregistered
  // party, posted without FBR), or 'manual' (backdated from another system).
  // Set at creation; immutable.
  origin: text("origin").notNull().default("fbr"),
  // Snapshot of the party's credit days at post time (calendar days from the
  // posting date). null = untracked (never overdue).
  dueDays: integer("due_days"),
  // FBR's returned top-level invoice number once posted (nullable pre-post).
  fbrInvoiceNumber: text("fbr_invoice_number"),
  // 00 = valid, 01 = invalid (nullable until a post attempt).
  fbrStatusCode: text("fbr_status_code"),
  // Full FBR raw response for audit/debug (jsonb). Populated on post attempts.
  fbrRawResponse: jsonb("fbr_raw_response"),

  totalValue: numeric("total_value", { precision: 14, scale: 2 }).notNull().default("0"),
  totalTax: numeric("total_tax", { precision: 14, scale: 2 }).notNull().default("0"),
  grandTotal: numeric("grand_total", { precision: 14, scale: 2 }).notNull().default("0"),

  createdBy: text("created_by").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
  postedAt: timestamp("posted_at"),
}, (t) => [
  index("invoice_party_status_idx").on(t.partyId, t.status),
]);

export const insertInvoiceSchema = createInsertSchema(invoiceTable).omit({
  id: true,
  status: true,
  origin: true,
  dueDays: true,
  fbrInvoiceNumber: true,
  fbrStatusCode: true,
  fbrRawResponse: true,
  createdAt: true,
  updatedAt: true,
  postedAt: true,
});
export type InsertInvoice = z.infer<typeof insertInvoiceSchema>;
export type Invoice = typeof invoiceTable.$inferSelect;

// ─── Invoice item (one per aggregated group) ───────────────────────────────
export const invoiceItemTable = pgTable("invoice_item", {
  id: serial("id").primaryKey(),
  invoiceId: integer("invoice_id")
    .notNull()
    .references(() => invoiceTable.id, { onDelete: "cascade" }),
  yarnTypeId: integer("yarn_type_id")
    .notNull()
    .references(() => yarnTypeMasterTable.id),
  yarnCountId: integer("yarn_count_id")
    .references(() => yarnCountMasterTable.id),
  hsCode: text("hs_code"),
  uoM: text("uom"),
  productDescription: text("product_description"),
  // Summed net weight (kg) across the grouped detail rows.
  quantity: numeric("quantity", { precision: 12, scale: 3 }).notNull(),
  ratePerKg: numeric("rate_per_kg", { precision: 14, scale: 2 }).notNull(),
  valueExcludingTax: numeric("value_excluding_tax", { precision: 14, scale: 2 }).notNull(),
  taxAmount: numeric("tax_amount", { precision: 14, scale: 2 }).notNull(),
  totalValue: numeric("total_value", { precision: 14, scale: 2 }).notNull(),
  saleType: text("sale_type").notNull().default("Goods at standard rate (default)"),
}, (t) => [
  index("invoice_item_invoice_idx").on(t.invoiceId),
]);

export const insertInvoiceItemSchema = createInsertSchema(invoiceItemTable).omit({
  id: true,
  invoiceId: true,
});
export type InsertInvoiceItem = z.infer<typeof insertInvoiceItemSchema>;
export type InvoiceItem = typeof invoiceItemTable.$inferSelect;

// ─── Invoice ↔ transaction junction ───────────────────────────────────────
// Single source of truth for "which transactions are invoiced". A transaction
// is considered invoiced iff it has a row here. Deleting a draft invoice
// removes its junction rows, un-marking those transactions for re-invoicing.
// Posting an invoice permanently owns them (invoice becomes read-only).
export const invoiceTransactionTable = pgTable("invoice_transaction", {
  id: serial("id").primaryKey(),
  invoiceId: integer("invoice_id")
    .notNull()
    .references(() => invoiceTable.id, { onDelete: "cascade" }),
  transactionHeaderId: integer("transaction_header_id")
    .notNull()
    .references(() => transactionHeaderTable.id, { onDelete: "cascade" }),
}, (t) => [
  unique("invoice_transaction_unique").on(t.invoiceId, t.transactionHeaderId),
  unique("invoice_transaction_tx_unique").on(t.transactionHeaderId),
  index("invoice_transaction_invoice_idx").on(t.invoiceId),
]);

export const insertInvoiceTransactionSchema = createInsertSchema(invoiceTransactionTable).omit({ id: true });
export type InsertInvoiceTransaction = z.infer<typeof insertInvoiceTransactionSchema>;
export type InvoiceTransaction = typeof invoiceTransactionTable.$inferSelect;

// ─── Invoice payment ───────────────────────────────────────────────────────
// A payment recorded against an invoice. `amount` is the GROSS amount paid;
// `taxDeduction` is withholding tax (WHT) deducted, so the NET amount applied
// to the invoice = amount - taxDeduction. Partial payments are allowed; an
// invoice is considered paid when Σ (amount - taxDeduction) >= grandTotal.
export const invoicePaymentTable = pgTable("invoice_payment", {
  id: serial("id").primaryKey(),
  invoiceId: integer("invoice_id")
    .notNull()
    .references(() => invoiceTable.id, { onDelete: "cascade" }),
  amount: numeric("amount", { precision: 14, scale: 2 }).notNull(),
  taxDeduction: numeric("tax_deduction", { precision: 14, scale: 2 }).notNull().default("0"),
  paymentDate: date("payment_date").notNull(),
  method: text("method"),
  reference: text("reference"),
  notes: text("notes"),
  paidBy: text("paid_by").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
}, (t) => [
  index("invoice_payment_invoice_idx").on(t.invoiceId),
]);

export const insertInvoicePaymentSchema = createInsertSchema(invoicePaymentTable).omit({ id: true, createdAt: true });
export type InsertInvoicePayment = z.infer<typeof insertInvoicePaymentSchema>;
export type InvoicePayment = typeof invoicePaymentTable.$inferSelect;
