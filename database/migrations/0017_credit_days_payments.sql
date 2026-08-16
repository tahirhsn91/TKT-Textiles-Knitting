-- Credit days, payment tracking, invoice origin & backdated-invoice toggle (issue #189)
--
-- Adds:
--   1. party_master.credit_days  — integer, default 0 (0 = no credit tracking).
--   2. invoice.due_days          — snapshot (nullable) of credit days at post
--      time; null = untracked.
--   3. invoice.origin            — how the invoice was posted: 'fbr' | 'local'
--      | 'manual' (set at creation, immutable).
--   4. invoice_payment           — per-invoice payment records (partials
--      allowed), incl. WHT tax deduction (net applied = amount - tax_deduction).
--   5. configuration             — add 'allow_backdated_invoices' toggle
--      (code 0003, default false) to show/hide the backdated-invoice tool.
--
--> statement-breakpoint

-- ─── 1. party_master.credit_days ───────────────────────────────────────────
ALTER TABLE "party_master" ADD COLUMN IF NOT EXISTS "credit_days" integer DEFAULT 0 NOT NULL;
--> statement-breakpoint

-- ─── 2. invoice snapshot fields ────────────────────────────────────────────
ALTER TABLE "invoice" ADD COLUMN IF NOT EXISTS "due_days" integer;
--> statement-breakpoint
ALTER TABLE "invoice" ADD COLUMN IF NOT EXISTS "origin" text DEFAULT 'fbr';
--> statement-breakpoint

-- ─── 3. invoice_payment table ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "invoice_payment" (
	"id" serial PRIMARY KEY NOT NULL,
	"invoice_id" integer NOT NULL,
	"amount" numeric(14, 2) NOT NULL,
	"tax_deduction" numeric(14, 2) DEFAULT 0 NOT NULL,
	"payment_date" date NOT NULL,
	"method" text,
	"reference" text,
	"notes" text,
	"paid_by" text NOT NULL,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "invoice_payment" ADD CONSTRAINT "invoice_payment_invoice_id_invoice_id_fk" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoice"("id") ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint
CREATE INDEX "invoice_payment_invoice_idx" ON "invoice_payment" USING btree ("invoice_id");
--> statement-breakpoint

-- ─── 4. Allow-backdated-invoices toggle (default false) ────────────────────
INSERT INTO "configuration" ("name", "code", "description", "enabled")
VALUES ('Allow Backdated Invoices', '0003', 'when enabled, shows the manual "Create Backdated Invoice" tool to record invoices generated from another system', false)
ON CONFLICT ("code") DO NOTHING;
