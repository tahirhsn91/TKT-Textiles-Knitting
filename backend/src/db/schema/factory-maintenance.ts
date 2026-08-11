import {
  pgTable,
  serial,
  date,
  text,
  timestamp,
  check,
  index,
} from "drizzle-orm/pg-core";
import { sql } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

// ─── Factory Maintenance ───────────────────────────────────────────────────
// One row per factory (site) maintenance job. History-only (issue #109): no
// reconciliation, no plausibility. `category` is a free-text string normally
// taken from a fixed dropdown list in the UI (Electrical, Plumbing, … , Other)
// but stored as-is so a future change to that list never orphans history.
// Soft-delete via `status` keeps records with an undo path.
export const factoryMaintenanceTable = pgTable("factory_maintenance", {
  id: serial("id").primaryKey(),
  maintenanceDate: date("maintenance_date").notNull(),
  category: text("category").notNull().default("Other"),
  maintenanceWork: text("maintenance_work").notNull(),
  status: text("status").notNull().default("submitted"),
  createdBy: text("created_by").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedBy: text("updated_by"),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
}, (t) => [
  check("factory_maintenance_status_check", sql`${t.status} IN ('submitted', 'cancelled')`),
  // Serves the "Get maintenance by date" summary query directly.
  index("factory_maintenance_date_idx").on(t.maintenanceDate, t.status),
]);

export const insertFactoryMaintenanceSchema = createInsertSchema(factoryMaintenanceTable).omit({
  id: true,
  status: true,
  createdAt: true,
  updatedAt: true,
});
export type InsertFactoryMaintenance = z.infer<typeof insertFactoryMaintenanceSchema>;
export type FactoryMaintenance = typeof factoryMaintenanceTable.$inferSelect;
