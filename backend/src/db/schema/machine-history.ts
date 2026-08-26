import {
  pgTable,
  serial,
  integer,
  numeric,
  date,
  text,
  timestamp,
  index,
  check,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { machineMasterTable } from "./lookups.js";
import { tenantTable } from "./tenants.js";

// ─── Machine History (issue: machine needle/sinker audit trail) ─────────────
// One row per write against the machine master (create / update / delete).
// Stores a full snapshot of the machine's state AFTER the write so the history
// reads as a timeline: the machine's needle/sinker dates + brands (plus
// identity + making rate) at each point in time, tagged with the action and
// who/when.
//
// `machineId` is a NULLABLE FK: when a machine is hard-deleted we still want
// its history to survive, so we denormalize machine_number + name into the row
// and don't rely on joining back to machine_master for display. This keeps the
// History tab fully self-contained even after a machine is removed.
export const machineHistoryTable = pgTable("machine_history", {
    tenantId: integer("tenant_id").notNull().default(1).references(() => tenantTable.id, { onDelete: "cascade" }),
  id: serial("id").primaryKey(),
  machineId: integer("machine_id")
    .references(() => machineMasterTable.id, { onDelete: "set null" }),
  machineNumber: text("machine_number").notNull(),
  name: text("name").notNull(),
  makingRate: numeric("making_rate", { precision: 10, scale: 2 }),
  needleChangeDate: date("needle_change_date"),
  needleBrand: text("needle_brand"),
  sinkerChangeDate: date("sinker_change_date"),
  sinkerBrand: text("sinker_brand"),
  action: text("action").notNull(),
  changedBy: text("changed_by").notNull(),
  changedAt: timestamp("changed_at").notNull().defaultNow(),
}, (t) => [
  check("machine_history_action_check", sql`${t.action} IN ('created', 'updated', 'deleted')`),
  // Serves the History tab's newest-first listing directly.
  index("machine_history_changed_at_idx").on(t.changedAt),
  index("machine_history_machine_idx").on(t.machineId),
]);

export type MachineHistoryAction = "created" | "updated" | "deleted";

export const insertMachineHistorySchema = createInsertSchema(machineHistoryTable).omit({
  id: true,
  changedAt: true,
});
export type InsertMachineHistory = z.infer<typeof insertMachineHistorySchema>;
export type MachineHistory = typeof machineHistoryTable.$inferSelect;
