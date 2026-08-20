-- Attendance: one row per employee per calendar day marking presence.
-- Attendance is the source of present days for payroll. Operators (dept 0002)
-- are still paid on max(manual attendance present, production days) resolved
-- live at payroll generation; this table stores only the manual attendance.
-- A Sunday is stored as a normal present row (no separate Sunday/holiday flag,
-- derivable from the date). One month is one authoritative set upserted by
-- (employee_id, attendance_date) when the user clicks Save on the Attendance
-- grid. Rows cascade-delete with their employee.

--> statement-breakpoint

CREATE TABLE IF NOT EXISTS "attendance" (
	"id" serial PRIMARY KEY NOT NULL,
	"employee_id" integer NOT NULL,
	"attendance_date" date NOT NULL,
	"present" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint

ALTER TABLE "attendance" ADD CONSTRAINT "attendance_employee_id_employee_master_id_fk"
	FOREIGN KEY ("employee_id") REFERENCES "public"."employee_master"("id") ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint

ALTER TABLE "attendance" ADD CONSTRAINT "attendance_employee_date_unique" UNIQUE ("employee_id","attendance_date");
--> statement-breakpoint

CREATE INDEX IF NOT EXISTS "attendance_date_idx" ON "attendance" USING btree ("attendance_date");
