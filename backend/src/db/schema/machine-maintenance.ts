import {
  pgTable,
  serial,
  integer,
  numeric,
  date,
  text,
  timestamp,
  check,
  index,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { machineMasterTable } from "./lookups.js";

// ─── Machine Maintenance ───────────────────────────────────────────────────
// One row per machine maintenance job. History-only (issue #109): no
// reconciliation, no plausibility. Machine is a required FK to the machine
// master (rendered as machine_number); the work description is free text; cost
// (numeric) and vendor (free text) are both optional. Soft-delete via `status`
// keeps records in the system with an undo path.
export const machineMaintenanceTable = pgTable("machine_maintenance", {
  id: serial("id").primaryKey(),
  maintenanceDate: date("maintenance_date").notNull(),
  machineId: integer("machine_id")
    .notNull()
    .references(() => machineMasterTable.id),
  maintenanceWork: text("maintenance_work").notNull(),
  cost: numeric("cost", { precision: 12, scale: 3 }),
  vendor: text("vendor"),
  status: text("status").notNull().default("submitted"),
  createdBy: text("created_by").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedBy: text("updated_by"),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
}, (t) => [
  check("machine_maintenance_status_check", sql`${t.status} IN ('submitted', 'cancelled')`),
  check("machine_maintenance_cost_check", sql`(${t.cost} IS NULL OR ${t.cost} >= 0)`),
  // Serves the "Get maintenance by date" summary query directly.
  index("machine_maintenance_date_idx").on(t.maintenanceDate, t.status),
]);

export const insertMachineMaintenanceSchema = createInsertSchema(machineMaintenanceTable).omit({
  id: true,
  status: true,
  createdAt: true,
  updatedAt: true,
});
export type InsertMachineMaintenance = z.infer<typeof insertMachineMaintenanceSchema>;
export type MachineMaintenance = typeof machineMaintenanceTable.$inferSelect;
