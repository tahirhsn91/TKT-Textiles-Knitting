-- FBR Digital Invoicing: company (seller) master, part master/yarn type
-- extensions (buyer + HS code), invoice + invoice_item + invoice_transaction,
-- and the sandbox/production configuration toggle (code "0002").
-- Seed is idempotent (ON CONFLICT DO NOTHING) so re-runs are safe.
--> statement-breakpoint

-- ─── Company Info master (seller) ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "company_info_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"ntn_cnic" text NOT NULL,
	"province" text NOT NULL,
	"address" text NOT NULL,
	"fbr_sandbox_token" text,
	"fbr_production_token" text,
	"is_default" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint

-- ─── Party master (buyer) FBR fields ───────────────────────────────────────
ALTER TABLE "party_master" ADD COLUMN IF NOT EXISTS "ntn_cnic" text;--> statement-breakpoint
ALTER TABLE "party_master" ADD COLUMN IF NOT EXISTS "province" text;--> statement-breakpoint
ALTER TABLE "party_master" ADD COLUMN IF NOT EXISTS "address" text;--> statement-breakpoint
ALTER TABLE "party_master" ADD COLUMN IF NOT EXISTS "registration_type" text DEFAULT 'Unregistered';--> statement-breakpoint

-- ─── Yarn type master: HS code for FBR item mapping ────────────────────────
ALTER TABLE "yarn_type_master" ADD COLUMN IF NOT EXISTS "hs_code" text;--> statement-breakpoint

-- ─── FBR invoice header ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "invoice" (
	"id" serial PRIMARY KEY NOT NULL,
	"invoice_date" date NOT NULL,
	"company_id" integer NOT NULL,
	"party_id" integer NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"fbr_invoice_number" text,
	"fbr_status_code" text,
	"fbr_raw_response" jsonb,
	"total_value" numeric(14, 2) DEFAULT '0' NOT NULL,
	"total_tax" numeric(14, 2) DEFAULT '0' NOT NULL,
	"grand_total" numeric(14, 2) DEFAULT '0' NOT NULL,
	"created_by" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"posted_at" timestamp
);
--> statement-breakpoint
ALTER TABLE "invoice" ADD CONSTRAINT "invoice_company_id_company_info_master_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."company_info_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invoice" ADD CONSTRAINT "invoice_party_id_party_master_id_fk" FOREIGN KEY ("party_id") REFERENCES "public"."party_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "invoice_party_status_idx" ON "invoice" USING btree ("party_id","status");--> statement-breakpoint

-- ─── Invoice item ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "invoice_item" (
	"id" serial PRIMARY KEY NOT NULL,
	"invoice_id" integer NOT NULL,
	"yarn_type_id" integer NOT NULL,
	"yarn_count_id" integer,
	"hs_code" text,
	"uom" text,
	"product_description" text,
	"quantity" numeric(12, 3) NOT NULL,
	"rate_per_kg" numeric(14, 2) NOT NULL,
	"value_excluding_tax" numeric(14, 2) NOT NULL,
	"tax_amount" numeric(14, 2) NOT NULL,
	"total_value" numeric(14, 2) NOT NULL,
	"sale_type" text DEFAULT 'Goods at standard rate (default)' NOT NULL
);
--> statement-breakpoint
ALTER TABLE "invoice_item" ADD CONSTRAINT "invoice_item_invoice_id_invoice_id_fk" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoice"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invoice_item" ADD CONSTRAINT "invoice_item_yarn_type_id_yarn_type_master_id_fk" FOREIGN KEY ("yarn_type_id") REFERENCES "public"."yarn_type_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invoice_item" ADD CONSTRAINT "invoice_item_yarn_count_id_yarn_count_master_id_fk" FOREIGN KEY ("yarn_count_id") REFERENCES "public"."yarn_count_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "invoice_item_invoice_idx" ON "invoice_item" USING btree ("invoice_id");--> statement-breakpoint

-- ─── Invoice ↔ transaction junction ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "invoice_transaction" (
	"id" serial PRIMARY KEY NOT NULL,
	"invoice_id" integer NOT NULL,
	"transaction_header_id" integer NOT NULL,
	CONSTRAINT "invoice_transaction_unique" UNIQUE("invoice_id","transaction_header_id"),
	CONSTRAINT "invoice_transaction_tx_unique" UNIQUE("transaction_header_id")
);
--> statement-breakpoint
ALTER TABLE "invoice_transaction" ADD CONSTRAINT "invoice_transaction_invoice_id_invoice_id_fk" FOREIGN KEY ("invoice_id") REFERENCES "public"."invoice"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invoice_transaction" ADD CONSTRAINT "invoice_transaction_transaction_header_id_transaction_header_id_fk" FOREIGN KEY ("transaction_header_id") REFERENCES "public"."transaction_header"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "invoice_transaction_invoice_idx" ON "invoice_transaction" USING btree ("invoice_id");--> statement-breakpoint

-- ─── Sandbox/production toggle (default: enabled = sandbox) ────────────────
INSERT INTO "configuration" ("name", "code", "description", "enabled")
VALUES ('FBR DI Sandbox', '0002', 'used to enable/disable FBR Digital Invoicing sandbox environment; when enabled invoices post to sandbox, when disabled they post to production', true)
ON CONFLICT ("code") DO NOTHING;
