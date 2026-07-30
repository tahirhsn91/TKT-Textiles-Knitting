ALTER TABLE "daily_production_header" ADD COLUMN "reconciled" boolean DEFAULT false NOT NULL;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD COLUMN "reconciled_transaction_id" integer;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD COLUMN "reconciled_at" timestamp;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD CONSTRAINT "daily_production_header_reconciled_transaction_id_transaction_header_id_fk" FOREIGN KEY ("reconciled_transaction_id") REFERENCES "public"."transaction_header"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "daily_production_header_reconcile_idx" ON "daily_production_header" USING btree ("production_date","party_id","reconciled");
