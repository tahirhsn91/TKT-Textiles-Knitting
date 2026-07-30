CREATE TYPE "public"."shift" AS ENUM('Morning', 'Night');--> statement-breakpoint
ALTER TABLE "daily_production_detail" ADD COLUMN "created_at" timestamp DEFAULT now() NOT NULL;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD COLUMN "shift" "shift" NOT NULL;--> statement-breakpoint
CREATE INDEX "daily_production_header_summary_idx" ON "daily_production_header" USING btree ("production_date","machine_id","operator_id","party_id","shift");