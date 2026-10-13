-- Migration: 0029_employee_loans
-- Purpose: Employee loan module (Payroll → Loans, above Advances).
--   * employee_loans            — money given to an employee as a loan.
--   * employee_loan_deductions  — payroll recovery against that loan.
-- A loan is a single running balance per employee:
--   remaining = Σ(employee_loans.amount) − Σ(employee_loan_deductions.amount)
-- Deduction rows are written only when a salary entry is POSTED and removed
-- when it is Un-posted, so drafts never move the balance. The unique
-- (header_id, employee_id) constraint makes posting idempotent.
-- Idempotent: CREATE TABLE/INDEX IF NOT EXISTS; safe to re-run.
-- Date: 2026-10-13

BEGIN;

CREATE TABLE IF NOT EXISTS "employee_loans" (
  "tenant_id" integer NOT NULL DEFAULT 1,
  "id" serial PRIMARY KEY NOT NULL,
  "employee_id" integer NOT NULL,
  "date" date NOT NULL,
  "amount" numeric NOT NULL,
  "notes" text,
  "created_at" timestamp DEFAULT now()
);
--> statement-breakpoint

CREATE INDEX IF NOT EXISTS "employee_loans_employee_date_idx"
  ON "employee_loans" ("employee_id", "date");
--> statement-breakpoint

ALTER TABLE "employee_loans" ADD CONSTRAINT "employee_loans_tenant_id_tenants_id_fk"
  FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint

ALTER TABLE "employee_loans" ADD CONSTRAINT "employee_loans_employee_id_employee_master_id_fk"
  FOREIGN KEY ("employee_id") REFERENCES "public"."employee_master"("id") ON DELETE no action ON UPDATE no action;
--> statement-breakpoint

CREATE TABLE IF NOT EXISTS "employee_loan_deductions" (
  "tenant_id" integer NOT NULL DEFAULT 1,
  "id" serial PRIMARY KEY NOT NULL,
  "employee_id" integer NOT NULL,
  "header_id" integer NOT NULL,
  "month" integer NOT NULL,
  "year" integer NOT NULL,
  "date" date NOT NULL,
  "amount" numeric NOT NULL,
  "created_at" timestamp DEFAULT now()
);
--> statement-breakpoint

CREATE UNIQUE INDEX IF NOT EXISTS "employee_loan_deductions_header_employee_unique"
  ON "employee_loan_deductions" ("header_id", "employee_id");
--> statement-breakpoint

CREATE INDEX IF NOT EXISTS "employee_loan_deductions_employee_idx"
  ON "employee_loan_deductions" ("employee_id");
--> statement-breakpoint

ALTER TABLE "employee_loan_deductions" ADD CONSTRAINT "employee_loan_deductions_tenant_id_tenants_id_fk"
  FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint

ALTER TABLE "employee_loan_deductions" ADD CONSTRAINT "employee_loan_deductions_employee_id_employee_master_id_fk"
  FOREIGN KEY ("employee_id") REFERENCES "public"."employee_master"("id") ON DELETE no action ON UPDATE no action;
--> statement-breakpoint

ALTER TABLE "employee_loan_deductions" ADD CONSTRAINT "employee_loan_deductions_header_id_salary_header_id_fk"
  FOREIGN KEY ("header_id") REFERENCES "public"."salary_header"("id") ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint

COMMIT;
