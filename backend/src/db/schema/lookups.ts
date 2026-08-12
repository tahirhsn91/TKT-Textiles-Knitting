import { pgTable, text, serial, unique, numeric, integer, timestamp, boolean, date } from "drizzle-orm/pg-core";
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

  // ─── FBR Digital Invoicing (buyer) ────────────────────────────────────────
  // Buyer-side fields required by the FBR DI API. ntn_cnic is optional (FBR
  // only requires it for Registered buyers; unregistered buyers leave it
  // blank). province is validated against FBR_PROVINCES; registration_type is
  // "Registered" | "Unregistered".
  ntnCnic: text("ntn_cnic"),
  province: text("province"),
  address: text("address"),
  registrationType: text("registration_type").default("Unregistered"),
});
export const insertPartyMasterSchema = createInsertSchema(partyMasterTable).omit({ id: true });
export type InsertPartyMaster = z.infer<typeof insertPartyMasterSchema>;
export type PartyMaster = typeof partyMasterTable.$inferSelect;

export const machineMasterTable = pgTable("machine_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  machineNumber: text("machine_number").notNull().unique(),
  makingRate: numeric("making_rate", { precision: 10, scale: 2 }).default("3.75"),
  needleChangeDate: date("needle_change_date"),
  needleBrand: text("needle_brand").default("Sigma"),
  sinkerChangeDate: date("sinker_change_date"),
  sinkerBrand: text("sinker_brand").default("Kohala"),
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
  // HS Code used on FBR invoices for items of this yarn type (e.g.
  // "6001.2100" for knit fabric). Empty until configured.
  hsCode: text("hs_code"),
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

export const departmentMasterTable = pgTable("department_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
});
export const insertDepartmentMasterSchema = createInsertSchema(departmentMasterTable).omit({ id: true });
export type InsertDepartmentMaster = z.infer<typeof insertDepartmentMasterSchema>;
export type DepartmentMaster = typeof departmentMasterTable.$inferSelect;

export const employeeMasterTable = pgTable("employee_master", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
  departmentId: integer("department_id"),
  baseSalary: numeric("base_salary", { precision: 10, scale: 2 }),
  overtimeRateHr: numeric("overtime_rate_hr", { precision: 10, scale: 2 }),
  attAllowance: numeric("att_allowance", { precision: 10, scale: 2 }),
  othAllowance: numeric("oth_allowance", { precision: 10, scale: 2 }),
  active: boolean("active").notNull().default(true),
});
export const insertEmployeeMasterSchema = createInsertSchema(employeeMasterTable).omit({ id: true });
export type InsertEmployeeMaster = z.infer<typeof insertEmployeeMasterSchema>;
export type EmployeeMaster = typeof employeeMasterTable.$inferSelect;

// ─── Employee Salary Settings ──────────────────────────────────────────────
export const employeeSalarySettingsTable = pgTable("employee_salary_settings", {
  id: serial("id").primaryKey(),
  employeeId: integer("employee_id").notNull().unique().references(() => employeeMasterTable.id),
  baseDailyWage: numeric("base_daily_wage").notNull().default("0"),
});
export const insertEmployeeSalarySettingsSchema = createInsertSchema(employeeSalarySettingsTable).omit({ id: true });
export type InsertEmployeeSalarySettings = z.infer<typeof insertEmployeeSalarySettingsSchema>;
export type EmployeeSalarySettings = typeof employeeSalarySettingsTable.$inferSelect;

// ─── Employee Salary Records ───────────────────────────────────────────────
export const employeeSalaryRecordsTable = pgTable("employee_salary_records", {
  id: serial("id").primaryKey(),
  employeeId: integer("employee_id").notNull().references(() => employeeMasterTable.id),
  date: text("date").notNull(),
  baseWage: numeric("base_wage").notNull(),
  commission: numeric("commission").notNull().default("0"),
  finalSalary: numeric("final_salary").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
}, (t) => ({ uniq: unique().on(t.employeeId, t.date) }));
export const insertEmployeeSalaryRecordsSchema = createInsertSchema(employeeSalaryRecordsTable).omit({ id: true, createdAt: true });
export type InsertEmployeeSalaryRecord = z.infer<typeof insertEmployeeSalaryRecordsSchema>;
export type EmployeeSalaryRecord = typeof employeeSalaryRecordsTable.$inferSelect;

// ─── Employee Advances ─────────────────────────────────────────────────────
export const employeeAdvancesTable = pgTable("employee_advances", {
  id: serial("id").primaryKey(),
  employeeId: integer("employee_id").notNull().references(() => employeeMasterTable.id),
  date: text("date").notNull(),
  amount: numeric("amount").notNull(),
  notes: text("notes"),
  createdAt: timestamp("created_at").defaultNow(),
});
export const insertEmployeeAdvancesSchema = createInsertSchema(employeeAdvancesTable).omit({ id: true, createdAt: true });
export type InsertEmployeeAdvance = z.infer<typeof insertEmployeeAdvancesSchema>;
export type EmployeeAdvance = typeof employeeAdvancesTable.$inferSelect;

// ─── Salary Header ─────────────────────────────────────────────────────────
export const salaryHeaderTable = pgTable("salary_header", {
  id: serial("id").primaryKey(),
  month: integer("month").notNull(),
  year: integer("year").notNull(),
  departmentIds: integer("department_ids").array().notNull().default([]),
  posted: boolean("posted").notNull().default(false),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});
export type SalaryHeader = typeof salaryHeaderTable.$inferSelect;

// ─── Salary Detail ─────────────────────────────────────────────────────────
export const salaryDetailTable = pgTable("salary_detail", {
  id: serial("id").primaryKey(),
  headerId: integer("header_id").notNull().references(() => salaryHeaderTable.id, { onDelete: "cascade" }),
  employeeId: integer("employee_id").notNull().references(() => employeeMasterTable.id),
  month: integer("month"),
  year: integer("year"),
  departmentId: integer("department_id"),
  employeeName: text("employee_name").notNull(),
  basicSalary: numeric("basic_salary", { precision: 10, scale: 2 }).notNull().default("0"),
  otRateHr: numeric("ot_rate_hr", { precision: 10, scale: 2 }).notNull().default("0"),
  attAllowance: numeric("att_allowance", { precision: 10, scale: 2 }).notNull().default("0"),
  othAllowance: numeric("oth_allowance", { precision: 10, scale: 2 }).notNull().default("0"),
  presentDays: numeric("present_days", { precision: 5, scale: 1 }).notNull().default("0"),
  absentDays: numeric("absent_days", { precision: 5, scale: 1 }).notNull().default("0"),
  holidays: numeric("holidays", { precision: 5, scale: 1 }).notNull().default("0"),
  totalAttendance: numeric("total_attendance", { precision: 5, scale: 1 }).notNull().default("0"),
  totalSalary: numeric("total_salary", { precision: 10, scale: 2 }).notNull().default("0"),
  otHours: numeric("ot_hours", { precision: 5, scale: 2 }).notNull().default("0"),
  otAmount: numeric("ot_amount", { precision: 10, scale: 2 }).notNull().default("0"),
  advanceDeduction: numeric("advance_deduction", { precision: 10, scale: 2 }).notNull().default("0"),
  loanDeduction: numeric("loan_deduction", { precision: 10, scale: 2 }).notNull().default("0"),
  otherDeduction: numeric("other_deduction", { precision: 10, scale: 2 }).notNull().default("0"),
  payableSalary: numeric("payable_salary", { precision: 10, scale: 2 }).notNull().default("0"),
}, (t) => [
  unique("salary_detail_header_employee_unique").on(t.headerId, t.employeeId),
  unique("salary_detail_emp_month_year_unique").on(t.employeeId, t.month, t.year),
]);
export type SalaryDetail = typeof salaryDetailTable.$inferSelect;
