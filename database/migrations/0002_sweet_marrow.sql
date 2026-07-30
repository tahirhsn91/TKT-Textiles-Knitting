CREATE TABLE "daily_production_detail" (
	"id" serial PRIMARY KEY NOT NULL,
	"header_id" integer NOT NULL,
	"roll_number" integer NOT NULL,
	"roll_weight" numeric(10, 3) NOT NULL,
	"remarks" text,
	CONSTRAINT "daily_production_detail_header_roll_unique" UNIQUE("header_id","roll_number"),
	CONSTRAINT "daily_production_detail_roll_weight_check" CHECK ("daily_production_detail"."roll_weight" > 0)
);
--> statement-breakpoint
CREATE TABLE "daily_production_header" (
	"id" serial PRIMARY KEY NOT NULL,
	"production_date" date NOT NULL,
	"machine_id" integer NOT NULL,
	"operator_id" integer NOT NULL,
	"party_id" integer NOT NULL,
	"status" text DEFAULT 'submitted' NOT NULL,
	"remarks" text,
	"created_by" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_by" text,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "daily_production_header_status_check" CHECK ("daily_production_header"."status" IN ('submitted', 'cancelled'))
);
--> statement-breakpoint
ALTER TABLE "daily_production_detail" ADD CONSTRAINT "daily_production_detail_header_id_daily_production_header_id_fk" FOREIGN KEY ("header_id") REFERENCES "public"."daily_production_header"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD CONSTRAINT "daily_production_header_machine_id_machine_master_id_fk" FOREIGN KEY ("machine_id") REFERENCES "public"."machine_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD CONSTRAINT "daily_production_header_operator_id_machine_operator_master_id_fk" FOREIGN KEY ("operator_id") REFERENCES "public"."machine_operator_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "daily_production_header" ADD CONSTRAINT "daily_production_header_party_id_party_master_id_fk" FOREIGN KEY ("party_id") REFERENCES "public"."party_master"("id") ON DELETE no action ON UPDATE no action;