-- Issue #112: convert machine needle/sinker change dates from TEXT to DATE.
-- Values are already clean ISO dates (e.g. '2026-04-10'), so the cast is
-- safe. Columns stay nullable — a machine may not yet have a change date.
--> statement-breakpoint
ALTER TABLE "machine_master" ALTER COLUMN "needle_change_date" TYPE date USING ("needle_change_date"::date);--> statement-breakpoint
ALTER TABLE "machine_master" ALTER COLUMN "sinker_change_date" TYPE date USING ("sinker_change_date"::date);
