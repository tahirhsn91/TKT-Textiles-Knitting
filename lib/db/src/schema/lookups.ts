import { pgTable, text, serial, unique, numeric, integer, timestamp } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

export const transactionTypeMasterTable = pgTable("transaction_type_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
  action: text("action"),
});
export const insertTransactionTypeMasterSchema = createInsertSchema(transactionTypeMasterTable).omit({ id: true });
export type InsertTransactionTypeMaster = z.infer<typeof insertTransactionTypeMasterSchema>;
export type TransactionTypeMaster = typeof transactionTypeMasterTable.$inferSelect;

export const jobMasterTable = pgTable("job_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull(),
  partyId: integer("party_id"),
}, (t) => [
  unique("job_master_party_code_unique").on(t.partyId, t.code),
]);
export const insertJobMasterSchema = createInsertSchema(jobMasterTable).omit({ id: true });
export type InsertJobMaster = z.infer<typeof insertJobMasterSchema>;
export type JobMaster = typeof jobMasterTable.$inferSelect;

export const partyMasterTable = pgTable("party_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
  wastePercent: numeric("waste_percent", { precision: 5, scale: 2 }).default("1.00"),
});
export const insertPartyMasterSchema = createInsertSchema(partyMasterTable).omit({ id: true });
export type InsertPartyMaster = z.infer<typeof insertPartyMasterSchema>;
export type PartyMaster = typeof partyMasterTable.$inferSelect;

export const machineMasterTable = pgTable("machine_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  machineNumber: text("machine_number").notNull().unique(),
});
export const insertMachineMasterSchema = createInsertSchema(machineMasterTable).omit({ id: true });
export type InsertMachineMaster = z.infer<typeof insertMachineMasterSchema>;
export type MachineMaster = typeof machineMasterTable.$inferSelect;

export const locationMasterTable = pgTable("location_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
});
export const insertLocationMasterSchema = createInsertSchema(locationMasterTable).omit({ id: true });
export type InsertLocationMaster = z.infer<typeof insertLocationMasterSchema>;
export type LocationMaster = typeof locationMasterTable.$inferSelect;

export const yarnTypeMasterTable = pgTable("yarn_type_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  makeRate: numeric("make_rate"),
  code: text("code").notNull().unique(),
});
export const insertYarnTypeMasterSchema = createInsertSchema(yarnTypeMasterTable).omit({ id: true });
export type InsertYarnTypeMaster = z.infer<typeof insertYarnTypeMasterSchema>;
export type YarnTypeMaster = typeof yarnTypeMasterTable.$inferSelect;

export const yarnCountMasterTable = pgTable("yarn_count_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  count: text("count").notNull().unique(),
});
export const insertYarnCountMasterSchema = createInsertSchema(yarnCountMasterTable).omit({ id: true });
export type InsertYarnCountMaster = z.infer<typeof insertYarnCountMasterSchema>;
export type YarnCountMaster = typeof yarnCountMasterTable.$inferSelect;

export const yarnBrandMasterTable = pgTable("yarn_brand_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
});
export const insertYarnBrandMasterSchema = createInsertSchema(yarnBrandMasterTable).omit({ id: true });
export type InsertYarnBrandMaster = z.infer<typeof insertYarnBrandMasterSchema>;
export type YarnBrandMaster = typeof yarnBrandMasterTable.$inferSelect;

export const uomMasterTable = pgTable("uom_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  abbreviation: text("abbreviation").notNull().unique(),
});
export const insertUomMasterSchema = createInsertSchema(uomMasterTable).omit({ id: true });
export type InsertUomMaster = z.infer<typeof insertUomMasterSchema>;
export type UomMaster = typeof uomMasterTable.$inferSelect;

export const fabricTypeMasterTable = pgTable("fabric_type_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
});
export const insertFabricTypeMasterSchema = createInsertSchema(fabricTypeMasterTable).omit({ id: true });
export type InsertFabricTypeMaster = z.infer<typeof insertFabricTypeMasterSchema>;
export type FabricTypeMaster = typeof fabricTypeMasterTable.$inferSelect;

export const machineOperatorMasterTable = pgTable("machine_operator_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
});
export const insertMachineOperatorMasterSchema = createInsertSchema(machineOperatorMasterTable).omit({ id: true });
export type InsertMachineOperatorMaster = z.infer<typeof insertMachineOperatorMasterSchema>;
export type MachineOperatorMaster = typeof machineOperatorMasterTable.$inferSelect;

// ─── Operator Salary Settings ──────────────────────────────────────────────
export const operatorSalarySettingsTable = pgTable("operator_salary_settings", {
  id: serial("id").primaryKey(),
  operatorId: integer("operator_id").notNull().unique().references(() => machineOperatorMasterTable.id),
  baseDailyWage: numeric("base_daily_wage").notNull().default("0"),
});
export const insertOperatorSalarySettingsSchema = createInsertSchema(operatorSalarySettingsTable).omit({ id: true });
export type InsertOperatorSalarySettings = z.infer<typeof insertOperatorSalarySettingsSchema>;
export type OperatorSalarySettings = typeof operatorSalarySettingsTable.$inferSelect;

// ─── Operator Salary Records ───────────────────────────────────────────────
export const operatorSalaryRecordsTable = pgTable("operator_salary_records", {
  id: serial("id").primaryKey(),
  operatorId: integer("operator_id").notNull().references(() => machineOperatorMasterTable.id),
  date: text("date").notNull(),
  baseWage: numeric("base_wage").notNull(),
  commission: numeric("commission").notNull().default("0"),
  finalSalary: numeric("final_salary").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
}, (t) => ({ uniq: unique().on(t.operatorId, t.date) }));
export const insertOperatorSalaryRecordsSchema = createInsertSchema(operatorSalaryRecordsTable).omit({ id: true, createdAt: true });
export type InsertOperatorSalaryRecord = z.infer<typeof insertOperatorSalaryRecordsSchema>;
export type OperatorSalaryRecord = typeof operatorSalaryRecordsTable.$inferSelect;

// ─── Operator Advances ─────────────────────────────────────────────────────
export const operatorAdvancesTable = pgTable("operator_advances", {
  id: serial("id").primaryKey(),
  operatorId: integer("operator_id").notNull().references(() => machineOperatorMasterTable.id),
  date: text("date").notNull(),
  amount: numeric("amount").notNull(),
  notes: text("notes"),
  createdAt: timestamp("created_at").defaultNow(),
});
export const insertOperatorAdvancesSchema = createInsertSchema(operatorAdvancesTable).omit({ id: true, createdAt: true });
export type InsertOperatorAdvance = z.infer<typeof insertOperatorAdvancesSchema>;
export type OperatorAdvance = typeof operatorAdvancesTable.$inferSelect;
