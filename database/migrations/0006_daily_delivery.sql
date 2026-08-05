CREATE TABLE IF NOT EXISTS "daily_delivery" (
	"id" serial PRIMARY KEY NOT NULL,
	"delivery_date" date NOT NULL,
	"party_id" integer NOT NULL,
	"challan_no" text NOT NULL,
	"sl" text,
	"gsm" integer,
	"quantity" integer NOT NULL,
	"net_weight" numeric(12, 3) NOT NULL,
	"status" text DEFAULT 'submitted' NOT NULL,
	"created_by" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_by" text,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"reconciled" boolean DEFAULT false NOT NULL,
	"reconciled_transaction_id" integer,
	"reconciled_at" timestamp,
	CONSTRAINT "daily_delivery_status_check" CHECK ("daily_delivery"."status" IN ('submitted', 'cancelled')),
	CONSTRAINT "daily_delivery_quantity_check" CHECK ("daily_delivery"."quantity" > 0),
	CONSTRAINT "daily_delivery_net_weight_check" CHECK ("daily_delivery"."net_weight" > 0)
);
--> statement-breakpoint
ALTER TABLE "daily_delivery" ADD CONSTRAINT "daily_delivery_party_id_party_master_id_fk" FOREIGN KEY ("party_id") REFERENCES "public"."party_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "daily_delivery" ADD CONSTRAINT "daily_delivery_reconciled_transaction_id_transaction_header_id_fk" FOREIGN KEY ("reconciled_transaction_id") REFERENCES "public"."transaction_header"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "daily_delivery_reconcile_idx" ON "daily_delivery" USING btree ("delivery_date","party_id","reconciled");--> statement-breakpoint
CREATE INDEX "daily_delivery_date_idx" ON "daily_delivery" USING btree ("delivery_date","party_id");
