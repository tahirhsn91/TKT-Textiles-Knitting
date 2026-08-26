import {
  pgTable,
  serial,
  integer,
  date,
  boolean,
  timestamp,
  unique,
  index,
} from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";
import { employeeMasterTable } from "./lookups.js";
import { tenantTable } from "./tenants.js";

// ─── Attendance ────────────────────────────────────────────────────────────
// One row per employee per calendar day, marking presence (present = true) or
// absence (false). Sundays are presented to non-operators as pre-checked
// Present days in the UI, but the raw row here is just `present` — a Sunday is
// a normal present row, no separate Sunday/holiday flag (derivable from date).
// A month of attendance is one authoritative set upserted by (employee_id,
// date) when the user clicks Save on the Attendance grid.
//
// Attendance is the source of present days for payroll. Operators (dept 0002)
// are still paid on `max(attendance present, production days)` resolved live
// at payroll generation; this table stores only the manual attendance.
export const attendanceTable = pgTable(
  "attendance",
  {
    tenantId: integer("tenant_id").notNull().default(1).references(() => tenantTable.id, { onDelete: "cascade" }),
    id: serial("id").primaryKey(),
    employeeId: integer("employee_id")
      .notNull()
      .references(() => employeeMasterTable.id, { onDelete: "cascade" }),
    attendanceDate: date("attendance_date").notNull(),
    present: boolean("present").notNull().default(false),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (t) => [
    // One authoritative presence value per employee per day.
    unique("attendance_employee_date_unique").on(t.employeeId, t.attendanceDate),
    // Serves "all attendance for a month" (WHERE attendance_date between …
    // AND …) on the grid load, and the "attendance exists for this month"
    // payroll gate (WHERE attendanceDate >= … AND <= … LIMIT 1).
    index("attendance_date_idx").on(t.attendanceDate),
  ],
);

export const insertAttendanceSchema = createInsertSchema(attendanceTable).omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});
export type InsertAttendance = z.infer<typeof insertAttendanceSchema>;
export type Attendance = typeof attendanceTable.$inferSelect;
