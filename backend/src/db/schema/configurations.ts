import {pgTable, serial, text, boolean, integer} from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { tenantTable } from "./tenants.js";

// System configuration table.
// Read-only from the UI and API: records are created/updated/deleted only via
// database migration (the seed below ships the first row). The API deliberately
// exposes GET only — no POST/PUT/DELETE routes exist.
export const configurationTable = pgTable("configuration", {
    tenantId: integer("tenant_id").notNull().default(1).references(() => tenantTable.id, { onDelete: "cascade" }),
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  code: text("code").notNull().unique(),
  description: text("description"),
  enabled: boolean("enabled").notNull().default(true),
});
export const insertConfigurationSchema = createInsertSchema(configurationTable).omit({ id: true });
export type InsertConfiguration = z.infer<typeof insertConfigurationSchema>;
export type Configuration = typeof configurationTable.$inferSelect;
