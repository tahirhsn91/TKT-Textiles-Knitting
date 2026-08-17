import {
  pgTable,
  text,
  serial,
  integer,
  numeric,
  date,
  index,
} from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import {
  transactionTypeMasterTable,
  jobMasterTable,
  partyMasterTable,
  machineMasterTable,
  locationMasterTable,
  yarnTypeMasterTable,
  yarnCountMasterTable,
  yarnBrandMasterTable,
  uomMasterTable,
  fabricTypeMasterTable,
  employeeMasterTable,
} from "./lookups.js";

export const transactionHeaderTable = pgTable("transaction_header", {
  id: serial("id").primaryKey(),
  transactionTypeId: integer("transaction_type_id")
    .notNull()
    .references(() => transactionTypeMasterTable.id),
  date: date("date").notNull(),
  docNumber: text("doc_number").notNull(),
  jobId: integer("job_id").references(() => jobMasterTable.id),
  partyId: integer("party_id").references(() => partyMasterTable.id),
  locationId: integer("location_id").references(() => locationMasterTable.id),
  fabricTypeId: integer("fabric_type_id").references(() => fabricTypeMasterTable.id),
  sl: text("sl"),
  gsm: integer("gsm"),
  reference: text("reference"),
}, (t) => [
  // Serves the per-day date-range filters (dashboard KPIs/trends, daily
  // summaries, reports) without a seq scan of the header table.
  index("transaction_header_date_idx").on(t.date),
  // Serves the invoice engine's un-invoiced lookup, party analytics, machine
  // analytics and salary operator-production (all filter by type (+ party) +
  // date range).
  index("transaction_header_type_party_date_idx").on(t.transactionTypeId, t.partyId, t.date),
  // Serves the CSV-import duplicate check (WHERE doc_number IN (...)) and the
  // suggestions SQL aggregate's MAX scan.
  index("transaction_header_doc_number_idx").on(t.docNumber),
]);

export const insertTransactionHeaderSchema = createInsertSchema(transactionHeaderTable).omit({ id: true });
export type InsertTransactionHeader = z.infer<typeof insertTransactionHeaderSchema>;
export type TransactionHeader = typeof transactionHeaderTable.$inferSelect;

export const transactionDetailTable = pgTable("transaction_detail", {
  id: serial("id").primaryKey(),
  headerId: integer("header_id")
    .notNull()
    .references(() => transactionHeaderTable.id, { onDelete: "cascade" }),
  machineId: integer("machine_id").references(() => machineMasterTable.id),
  employeeId: integer("employee_id").references(() => employeeMasterTable.id),
  yarnTypeId: integer("yarn_type_id").references(() => yarnTypeMasterTable.id),
  yarnCountId: integer("yarn_count_id").references(() => yarnCountMasterTable.id),
  yarnBrandId: integer("yarn_brand_id").references(() => yarnBrandMasterTable.id),
  uomId: integer("uom_id").references(() => uomMasterTable.id),
  quantity: numeric("quantity", { precision: 12, scale: 3 }),
  netWt: numeric("net_wt", { precision: 12, scale: 3 }),
}, (t) => [
  // The FK does NOT auto-index the referencing column in Postgres; this serves
  // the constant header→details lookups (load/delete/update), the invoice
  // engine's details fetch, and the dashboard/reports joins.
  index("transaction_detail_header_idx").on(t.headerId),
]);

export const insertTransactionDetailSchema = createInsertSchema(transactionDetailTable).omit({ id: true });
export type InsertTransactionDetail = z.infer<typeof insertTransactionDetailSchema>;
export type TransactionDetail = typeof transactionDetailTable.$inferSelect;
