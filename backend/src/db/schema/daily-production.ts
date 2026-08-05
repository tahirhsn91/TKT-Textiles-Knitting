import {
  pgTable,
  pgEnum,
  serial,
  integer,
  numeric,
  date,
  text,
  timestamp,
  boolean,
  unique,
  check,
  index,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import {
  machineMasterTable,
  employeeMasterTable,
  partyMasterTable,
} from "./lookups.js";
import { transactionHeaderTable } from "./transactions.js";

// A genuine Postgres ENUM type (not a text + CHECK constraint) — the
// requirement is explicit that Shift is "stored as an Enum in the database".
// Adding a third shift later requires an ALTER TYPE ... ADD VALUE migration;
// flagged as an open question in the TDD (fixed 2-value enums are cheap to
// extend but not free — see Section 2.4 of the design doc).
export const shiftEnum = pgEnum("shift", ["Morning", "Night"]);

// ─── Daily Production Header ───────────────────────────────────────────────
// One row per (date, machine, employee, party, shift) production *entry*.
// Multiple headers can legitimately share the same 5-way combination — e.g.
// a supervisor uses "Save & Add" twice for the same machine/shift — the main
// screen's summary grid aggregates SUM(roll_weight) across all of them
// (Section 1 requirement), so no uniqueness constraint is placed on the
// combination itself.
export const dailyProductionHeaderTable = pgTable("daily_production_header", {
  id: serial("id").primaryKey(),
  productionDate: date("production_date").notNull(),
  machineId: integer("machine_id")
    .notNull()
    .references(() => machineMasterTable.id),
  employeeId: integer("employee_id")
    .notNull()
    .references(() => employeeMasterTable.id),
  partyId: integer("party_id")
    .notNull()
    .references(() => partyMasterTable.id),
  shift: shiftEnum("shift").notNull(),
  // Soft status instead of hard delete — production rows are frequently
  // referenced downstream (yarn consumption, payroll); "cancelled" preserves
  // the audit trail instead of losing the row on DELETE. Also lets the
  // summary query exclude cancelled entries from totals without losing them.
  status: text("status").notNull().default("submitted"),
  remarks: text("remarks"),
  createdBy: text("created_by").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedBy: text("updated_by"),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),

  // ─── Reconciliation ──────────────────────────────────────────────────────
  // Set when a Fabric Production transaction consumes this entry. Locking is
  // PERMANENT by product decision: deleting the transaction does not release
  // the row. `reconciledTransactionId` is therefore an audit trail rather than
  // an unwind path — the FK is ON DELETE SET NULL so the row survives its
  // transaction being deleted and simply stops naming it. If a row is ever
  // locked in error, recovery is a manual UPDATE; there is no UI route back.
  reconciled: boolean("reconciled").notNull().default(false),
  reconciledTransactionId: integer("reconciled_transaction_id")
    .references(() => transactionHeaderTable.id, { onDelete: "set null" }),
  reconciledAt: timestamp("reconciled_at"),
}, (t) => [
  check("daily_production_header_status_check", sql`${t.status} IN ('submitted', 'cancelled')`),
  // Serves the "what is still available to reconcile for this date + party"
  // lookup the transaction form fires on every type/date/party change.
  index("daily_production_header_reconcile_idx").on(
    t.productionDate, t.partyId, t.reconciled,
  ),
  // Serves the "Get production summary by date" query directly: filter by
  // production_date, group by machine/employee/party/shift.
  index("daily_production_header_summary_idx").on(
    t.productionDate, t.machineId, t.employeeId, t.partyId, t.shift,
  ),
]);

// Reconciliation fields are server-controlled. Leaving them on the insert
// schema would let a client mark its own row reconciled — and because locking
// is permanent, that would be an unrecoverable write from untrusted input.
export const insertDailyProductionHeaderSchema = createInsertSchema(dailyProductionHeaderTable).omit({
  id: true,
  createdAt: true,
  updatedAt: true,
  reconciled: true,
  reconciledTransactionId: true,
  reconciledAt: true,
});
export type InsertDailyProductionHeader = z.infer<typeof insertDailyProductionHeaderSchema>;
export type DailyProductionHeader = typeof dailyProductionHeaderTable.$inferSelect;

// ─── Daily Production Detail ───────────────────────────────────────────────
// One row per physical yarn roll produced against the header.
export const dailyProductionDetailTable = pgTable("daily_production_detail", {
  id: serial("id").primaryKey(),
  headerId: integer("header_id")
    .notNull()
    .references(() => dailyProductionHeaderTable.id, { onDelete: "cascade" }),
  rollNumber: integer("roll_number").notNull(),
  rollWeight: numeric("roll_weight", { precision: 10, scale: 3 }).notNull(),
  remarks: text("remarks"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
}, (t) => [
  unique("daily_production_detail_header_roll_unique").on(t.headerId, t.rollNumber),
  check("daily_production_detail_roll_weight_check", sql`${t.rollWeight} > 0`),
]);

export const insertDailyProductionDetailSchema = createInsertSchema(dailyProductionDetailTable).omit({
  id: true,
  headerId: true,
  createdAt: true,
});
export type InsertDailyProductionDetail = z.infer<typeof insertDailyProductionDetailSchema>;
export type DailyProductionDetail = typeof dailyProductionDetailTable.$inferSelect;
