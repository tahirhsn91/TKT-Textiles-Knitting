-- Machine History: audit trail for the machine master's needle/sinker data.
-- One row is written for every create/update/delete against machine_master,
-- storing the machine's state AFTER the write (a timeline). machine_id is a
-- NULLABLE FK — when a machine is hard-deleted we keep its history, so
-- machine_number + name are denormalized here and display never relies on a
-- join back to machine_master.

--> statement-breakpoint

CREATE TABLE IF NOT EXISTS "machine_history" (
	"id" serial PRIMARY KEY NOT NULL,
	"machine_id" integer,
	"machine_number" text NOT NULL,
	"name" text NOT NULL,
	"making_rate" numeric(10, 2),
	"needle_change_date" date,
	"needle_brand" text,
	"sinker_change_date" date,
	"sinker_brand" text,
	"action" text NOT NULL,
	"changed_by" text NOT NULL,
	"changed_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint

ALTER TABLE "machine_history" ADD CONSTRAINT "machine_history_machine_id_machine_master_id_fk"
	FOREIGN KEY ("machine_id") REFERENCES "public"."machine_master"("id") ON DELETE set null ON UPDATE no action;
--> statement-breakpoint

ALTER TABLE "machine_history" ADD CONSTRAINT "machine_history_action_check"
	CHECK ("action" IN ('created', 'updated', 'deleted'));
--> statement-breakpoint

CREATE INDEX IF NOT EXISTS "machine_history_changed_at_idx" ON "machine_history" ("changed_at");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "machine_history_machine_idx" ON "machine_history" ("machine_id");
