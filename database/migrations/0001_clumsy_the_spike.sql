CREATE TABLE "department_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	CONSTRAINT "department_master_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "salary_detail" (
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
CREATE TABLE "salary_header" (
	"id" serial PRIMARY KEY NOT NULL,
	"month" integer NOT NULL,
	"year" integer NOT NULL,
	"department_ids" integer[] DEFAULT '{}' NOT NULL,
	"posted" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
ALTER TABLE "machine_master" ADD COLUMN "making_rate" numeric(10, 2) DEFAULT '3.75';--> statement-breakpoint
ALTER TABLE "machine_master" ADD COLUMN "needle_change_date" text;--> statement-breakpoint
ALTER TABLE "machine_master" ADD COLUMN "needle_brand" text DEFAULT 'Sigma';--> statement-breakpoint
ALTER TABLE "machine_master" ADD COLUMN "sinker_change_date" text;--> statement-breakpoint
ALTER TABLE "machine_master" ADD COLUMN "sinker_brand" text DEFAULT 'Kohala';--> statement-breakpoint
ALTER TABLE "machine_operator_master" ADD COLUMN "department_id" integer;--> statement-breakpoint
ALTER TABLE "machine_operator_master" ADD COLUMN "base_salary" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "machine_operator_master" ADD COLUMN "overtime_rate_hr" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "machine_operator_master" ADD COLUMN "att_allowance" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "machine_operator_master" ADD COLUMN "oth_allowance" numeric(10, 2);--> statement-breakpoint
ALTER TABLE "machine_operator_master" ADD COLUMN "active" boolean DEFAULT true NOT NULL;--> statement-breakpoint
ALTER TABLE "salary_detail" ADD CONSTRAINT "salary_detail_header_id_salary_header_id_fk" FOREIGN KEY ("header_id") REFERENCES "public"."salary_header"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "salary_detail" ADD CONSTRAINT "salary_detail_operator_id_machine_operator_master_id_fk" FOREIGN KEY ("operator_id") REFERENCES "public"."machine_operator_master"("id") ON DELETE no action ON UPDATE no action;