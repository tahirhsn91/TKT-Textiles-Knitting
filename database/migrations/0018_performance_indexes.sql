-- Performance indexes (database optimization pass)
--
-- Adds the indexes declared in the Drizzle schema (backend/src/db/schema/*.ts)
-- that were never emitted by an earlier migration, plus two new ones for hot
-- filter paths. Postgres does NOT auto-index FK referencing columns, so every
-- header→detail FK used in a WHERE/JOIN gets an explicit index here.
--
-- All statements are idempotent (IF NOT EXISTS) and safe to run at any time,
-- including against a live production DB — CREATE INDEX takes a brief ACCESS
-- EXCLUSIVE-ish lock (SHARE) but does not rewrite or validate data. On very
-- large tables prefer `CREATE INDEX CONCURRENTLY` (cannot run inside a
-- transaction; run statements individually in that case).
--> statement-breakpoint

-- ─── transaction_header (largest table; dashboard/party-analytics/machine-
-- analytics/salary/invoice-engine all filter by these) ─────────────────────
-- Plain date-range filter (dashboard KPIs/trends, daily summaries, reports).
CREATE INDEX IF NOT EXISTS "transaction_header_date_idx" ON "transaction_header" USING btree ("date");
--> statement-breakpoint
-- Invoice engine's un-invoiced lookup, party analytics, machine analytics,
-- salary operator-production: all filter by type (+ party) + date range.
CREATE INDEX IF NOT EXISTS "transaction_header_type_party_date_idx" ON "transaction_header" USING btree ("transaction_type_id","party_id","date");
--> statement-breakpoint
-- CSV-import duplicate check (WHERE doc_number IN (...)) and the
-- suggestions SQL aggregate's MAX scan.
CREATE INDEX IF NOT EXISTS "transaction_header_doc_number_idx" ON "transaction_header" USING btree ("doc_number");
--> statement-breakpoint

-- ─── transaction_detail ────────────────────────────────────────────────────
-- FK column (header_id) — serves the constant header→details lookups
-- (load/delete/update), the invoice engine's details fetch, and the
-- dashboard/reports joins.
CREATE INDEX IF NOT EXISTS "transaction_detail_header_idx" ON "transaction_detail" USING btree ("header_id");
--> statement-breakpoint

-- ─── daily_production_detail ───────────────────────────────────────────────
-- FK column (header_id) — summary counts/sums, edit, delete, plausibility.
CREATE INDEX IF NOT EXISTS "daily_production_detail_header_idx" ON "daily_production_detail" USING btree ("header_id");
--> statement-breakpoint

-- ─── yarn_receipt_detail / yarn_receipt_header ─────────────────────────────
-- FK column (header_id) — list/analytics/update/delete.
CREATE INDEX IF NOT EXISTS "yarn_receipt_detail_header_idx" ON "yarn_receipt_detail" USING btree ("header_id");
-- The "what is still available to book for this date + party" lookup the
-- transaction form fires on every type/date/party change. Declared in the
-- Drizzle schema since the reconciliation feature shipped but never emitted
-- by a migration (schema drift — fixed here).
CREATE INDEX IF NOT EXISTS "yarn_receipt_header_reconcile_idx" ON "yarn_receipt_header" USING btree ("receipt_date","party_id","reconciled");
--> statement-breakpoint

-- ─── salary tables ─────────────────────────────────────────────────────────
-- FK column (header_id) — detail page, delete-then-reinsert on update.
CREATE INDEX IF NOT EXISTS "salary_detail_header_idx" ON "salary_detail" USING btree ("header_id");
-- The salary list screen filters by (year, month) in SQL and orders by
-- (year, month); one index row per payroll run.
CREATE INDEX IF NOT EXISTS "salary_header_month_year_idx" ON "salary_header" USING btree ("year","month");
--> statement-breakpoint

-- ─── employee_advances ─────────────────────────────────────────────────────
-- Advances list + payroll summary filter by employee + date range; this
-- table previously had NO index besides the PK.
CREATE INDEX IF NOT EXISTS "employee_advances_employee_date_idx" ON "employee_advances" USING btree ("employee_id","date");
