CREATE TABLE IF NOT EXISTS "machine_maintenance" (
	"id" serial PRIMARY KEY NOT NULL,
	"maintenance_date" date NOT NULL,
	"machine_id" integer NOT NULL,
	"maintenance_work" text NOT NULL,
	"cost" numeric(12, 3),
	"vendor" text,
	"status" text DEFAULT 'submitted' NOT NULL,
	"created_by" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_by" text,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "machine_maintenance_status_check" CHECK ("machine_maintenance"."status" IN ('submitted', 'cancelled')),
	CONSTRAINT "machine_maintenance_cost_check" CHECK ("machine_maintenance"."cost" IS NULL OR "machine_maintenance"."cost" >= 0)
);
--> statement-breakpoint
ALTER TABLE "machine_maintenance" ADD CONSTRAINT "machine_maintenance_machine_id_machine_master_id_fk" FOREIGN KEY ("machine_id") REFERENCES "public"."machine_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "machine_maintenance_date_idx" ON "machine_maintenance" USING btree ("maintenance_date","status");
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "factory_maintenance" (
	"id" serial PRIMARY KEY NOT NULL,
	"maintenance_date" date NOT NULL,
	"category" text DEFAULT 'Other' NOT NULL,
	"maintenance_work" text NOT NULL,
	"status" text DEFAULT 'submitted' NOT NULL,
	"created_by" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_by" text,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "factory_maintenance_status_check" CHECK ("factory_maintenance"."status" IN ('submitted', 'cancelled'))
);
--> statement-breakpoint
CREATE INDEX "factory_maintenance_date_idx" ON "factory_maintenance" USING btree ("maintenance_date","status");
