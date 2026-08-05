CREATE TABLE "yarn_receipt_detail" (
	"id" serial PRIMARY KEY NOT NULL,
	"header_id" integer NOT NULL,
	"yarn_type_id" integer NOT NULL,
	"yarn_count_id" integer NOT NULL,
	"quantity" integer NOT NULL,
	"net_weight" numeric(12, 3) NOT NULL,
	CONSTRAINT "yarn_receipt_detail_quantity_check" CHECK ("yarn_receipt_detail"."quantity" > 0),
	CONSTRAINT "yarn_receipt_detail_net_weight_check" CHECK ("yarn_receipt_detail"."net_weight" > 0)
);
--> statement-breakpoint
CREATE TABLE "yarn_receipt_header" (
	"id" serial PRIMARY KEY NOT NULL,
	"receipt_date" date NOT NULL,
	"party_id" integer NOT NULL,
	"status" text DEFAULT 'submitted' NOT NULL,
	"created_by" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_by" text,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "yarn_receipt_header_status_check" CHECK ("yarn_receipt_header"."status" IN ('submitted', 'cancelled'))
);
--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD COLUMN "reconciled" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD COLUMN "reconciled_transaction_id" integer;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD COLUMN "reconciled_at" timestamp;--> statement-breakpoint
ALTER TABLE "yarn_receipt_detail" ADD CONSTRAINT "yarn_receipt_detail_header_id_yarn_receipt_header_id_fk" FOREIGN KEY ("header_id") REFERENCES "public"."yarn_receipt_header"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "yarn_receipt_detail" ADD CONSTRAINT "yarn_receipt_detail_yarn_type_id_yarn_type_master_id_fk" FOREIGN KEY ("yarn_type_id") REFERENCES "public"."yarn_type_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "yarn_receipt_detail" ADD CONSTRAINT "yarn_receipt_detail_yarn_count_id_yarn_count_master_id_fk" FOREIGN KEY ("yarn_count_id") REFERENCES "public"."yarn_count_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "yarn_receipt_header" ADD CONSTRAINT "yarn_receipt_header_party_id_party_master_id_fk" FOREIGN KEY ("party_id") REFERENCES "public"."party_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "yarn_receipt_header_date_idx" ON "yarn_receipt_header" USING btree ("receipt_date","party_id");--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD CONSTRAINT "daily_production_header_reconciled_transaction_id_transaction_header_id_fk" FOREIGN KEY ("reconciled_transaction_id") REFERENCES "public"."transaction_header"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "daily_production_header_reconcile_idx" ON "daily_production_header" USING btree ("production_date","party_id","reconciled");