CREATE TABLE IF NOT EXISTS "salary_header" (
	"id" serial PRIMARY KEY NOT NULL,
	"month" integer NOT NULL,
	"year" integer NOT NULL,
	"department_ids" integer[] DEFAULT '{}' NOT NULL,
	"posted" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "salary_detail" (
	"id" serial PRIMARY KEY NOT NULL,
	"header_id" integer NOT NULL,
	"operator_id" integer NOT NULL,
	"month" integer,
	"year" integer,
	"department_id" integer,
	"operator_name" text NOT NULL,
	"basic_salary" numeric(10, 2) DEFAULT '0' NOT NULL,
	"ot_rate_hr" numeric(10, 2) DEFAULT '0' NOT NULL,
	"att_allowance" numeric(10, 2) DEFAULT '0' NOT NULL,
	"oth_allowance" numeric(10, 2) DEFAULT '0' NOT NULL,
	"present_days" numeric(5, 1) DEFAULT '0' NOT NULL,
	"absent_days" numeric(5, 1) DEFAULT '0' NOT NULL,
	"holidays" numeric(5, 1) DEFAULT '0' NOT NULL,
	"total_attendance" numeric(5, 1) DEFAULT '0' NOT NULL,
	"total_salary" numeric(10, 2) DEFAULT '0' NOT NULL,
	"ot_hours" numeric(5, 2) DEFAULT '0' NOT NULL,
	"ot_amount" numeric(10, 2) DEFAULT '0' NOT NULL,
	"advance_deduction" numeric(10, 2) DEFAULT '0' NOT NULL,
	"loan_deduction" numeric(10, 2) DEFAULT '0' NOT NULL,
	"other_deduction" numeric(10, 2) DEFAULT '0' NOT NULL,
	"payable_salary" numeric(10, 2) DEFAULT '0' NOT NULL,
	CONSTRAINT "salary_detail_header_operator_unique" UNIQUE("header_id","operator_id"),
	CONSTRAINT "salary_detail_op_month_year_unique" UNIQUE("operator_id","month","year")
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "salary_detail" ADD CONSTRAINT "salary_detail_header_id_salary_header_id_fk" FOREIGN KEY ("header_id") REFERENCES "public"."salary_header"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "salary_detail" ADD CONSTRAINT "salary_detail_operator_id_machine_operator_master_id_fk" FOREIGN KEY ("operator_id") REFERENCES "public"."machine_operator_master"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
