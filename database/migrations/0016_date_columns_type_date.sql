-- Date columns type change for employee advances & salary records (issue #12)
-- The `date` columns on employee_advances and employee_salary_records were stored
-- as TEXT (previously operator_advances / operator_salary_records before the
-- Operator→Employee rename). Convert them to the proper Postgres `date` type.
--
-- This is safe for the well-formed YYYY-MM-DD values the app writes today; the
-- USING date::date cast will raise an error if any existing value is not a valid
-- ISO date, so a bad row surfaces loudly rather than being silently truncated.
--> statement-breakpoint

-- ─── employee_advances.date ────────────────────────────────────────────────
ALTER TABLE "employee_advances"
	ALTER COLUMN "date" TYPE date USING "date"::date;
--> statement-breakpoint

-- ─── employee_salary_records.date ──────────────────────────────────────────
ALTER TABLE "employee_salary_records"
	ALTER COLUMN "date" TYPE date USING "date"::date;
