import {
  pgTable,
  text,
  serial,
  integer,
  numeric,
  date,
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
  machineOperatorMasterTable,
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
});

export const insertTransactionHeaderSchema = createInsertSchema(transactionHeaderTable).omit({ id: true });
export type InsertTransactionHeader = z.infer<typeof insertTransactionHeaderSchema>;
export type TransactionHeader = typeof transactionHeaderTable.$inferSelect;

export const transactionDetailTable = pgTable("transaction_detail", {
  id: serial("id").primaryKey(),
  headerId: integer("header_id")
    .notNull()
    .references(() => transactionHeaderTable.id, { onDelete: "cascade" }),
  machineId: integer("machine_id").references(() => machineMasterTable.id),
  machineOperatorId: integer("machine_operator_id").references(() => machineOperatorMasterTable.id),
  yarnTypeId: integer("yarn_type_id").references(() => yarnTypeMasterTable.id),
  yarnCountId: integer("yarn_count_id").references(() => yarnCountMasterTable.id),
  yarnBrandId: integer("yarn_brand_id").references(() => yarnBrandMasterTable.id),
  uomId: integer("uom_id").references(() => uomMasterTable.id),
  quantity: numeric("quantity", { precision: 12, scale: 3 }),
  netWt: numeric("net_wt", { precision: 12, scale: 3 }),
});

export const insertTransactionDetailSchema = createInsertSchema(transactionDetailTable).omit({ id: true });
export type InsertTransactionDetail = z.infer<typeof insertTransactionDetailSchema>;
export type TransactionDetail = typeof transactionDetailTable.$inferSelect;
