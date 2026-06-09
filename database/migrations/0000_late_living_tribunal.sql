CREATE TABLE "fabric_type_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	CONSTRAINT "fabric_type_master_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "job_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	"party_id" integer,
	CONSTRAINT "job_master_party_code_unique" UNIQUE("party_id","code")
);
--> statement-breakpoint
CREATE TABLE "location_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	CONSTRAINT "location_master_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "machine_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"machine_number" text NOT NULL,
	CONSTRAINT "machine_master_machine_number_unique" UNIQUE("machine_number")
);
--> statement-breakpoint
CREATE TABLE "machine_operator_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	CONSTRAINT "machine_operator_master_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "operator_advances" (
	"id" serial PRIMARY KEY NOT NULL,
	"operator_id" integer NOT NULL,
	"date" text NOT NULL,
	"amount" numeric NOT NULL,
	"notes" text,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "operator_salary_records" (
	"id" serial PRIMARY KEY NOT NULL,
	"operator_id" integer NOT NULL,
	"date" text NOT NULL,
	"base_wage" numeric NOT NULL,
	"commission" numeric DEFAULT '0' NOT NULL,
	"final_salary" numeric NOT NULL,
	"created_at" timestamp DEFAULT now(),
	CONSTRAINT "operator_salary_records_operator_id_date_unique" UNIQUE("operator_id","date")
);
--> statement-breakpoint
CREATE TABLE "operator_salary_settings" (
	"id" serial PRIMARY KEY NOT NULL,
	"operator_id" integer NOT NULL,
	"base_daily_wage" numeric DEFAULT '0' NOT NULL,
	CONSTRAINT "operator_salary_settings_operator_id_unique" UNIQUE("operator_id")
);
--> statement-breakpoint
CREATE TABLE "party_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	"waste_percent" numeric(5, 2) DEFAULT '1.00',
	CONSTRAINT "party_master_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "transaction_type_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	"action" text,
	CONSTRAINT "transaction_type_master_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "uom_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"abbreviation" text NOT NULL,
	CONSTRAINT "uom_master_abbreviation_unique" UNIQUE("abbreviation")
);
--> statement-breakpoint
CREATE TABLE "yarn_brand_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	CONSTRAINT "yarn_brand_master_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "yarn_count_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"count" text NOT NULL,
	CONSTRAINT "yarn_count_master_count_unique" UNIQUE("count")
);
--> statement-breakpoint
CREATE TABLE "yarn_type_master" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"make_rate" numeric,
	"code" text NOT NULL,
	CONSTRAINT "yarn_type_master_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "transaction_detail" (
	"id" serial PRIMARY KEY NOT NULL,
	"header_id" integer NOT NULL,
	"machine_id" integer,
	"machine_operator_id" integer,
	"yarn_type_id" integer,
	"yarn_count_id" integer,
	"yarn_brand_id" integer,
	"uom_id" integer,
	"quantity" numeric(12, 3),
	"net_wt" numeric(12, 3)
);
--> statement-breakpoint
CREATE TABLE "transaction_header" (
	"id" serial PRIMARY KEY NOT NULL,
	"transaction_type_id" integer NOT NULL,
	"date" date NOT NULL,
	"doc_number" text NOT NULL,
	"job_id" integer,
	"party_id" integer,
	"location_id" integer,
	"fabric_type_id" integer,
	"sl" text,
	"gsm" integer,
	"reference" text
);
--> statement-breakpoint
ALTER TABLE "operator_advances" ADD CONSTRAINT "operator_advances_operator_id_machine_operator_master_id_fk" FOREIGN KEY ("operator_id") REFERENCES "public"."machine_operator_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "operator_salary_records" ADD CONSTRAINT "operator_salary_records_operator_id_machine_operator_master_id_fk" FOREIGN KEY ("operator_id") REFERENCES "public"."machine_operator_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "operator_salary_settings" ADD CONSTRAINT "operator_salary_settings_operator_id_machine_operator_master_id_fk" FOREIGN KEY ("operator_id") REFERENCES "public"."machine_operator_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_detail" ADD CONSTRAINT "transaction_detail_header_id_transaction_header_id_fk" FOREIGN KEY ("header_id") REFERENCES "public"."transaction_header"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_detail" ADD CONSTRAINT "transaction_detail_machine_id_machine_master_id_fk" FOREIGN KEY ("machine_id") REFERENCES "public"."machine_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_detail" ADD CONSTRAINT "transaction_detail_machine_operator_id_machine_operator_master_id_fk" FOREIGN KEY ("machine_operator_id") REFERENCES "public"."machine_operator_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_detail" ADD CONSTRAINT "transaction_detail_yarn_type_id_yarn_type_master_id_fk" FOREIGN KEY ("yarn_type_id") REFERENCES "public"."yarn_type_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_detail" ADD CONSTRAINT "transaction_detail_yarn_count_id_yarn_count_master_id_fk" FOREIGN KEY ("yarn_count_id") REFERENCES "public"."yarn_count_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_detail" ADD CONSTRAINT "transaction_detail_yarn_brand_id_yarn_brand_master_id_fk" FOREIGN KEY ("yarn_brand_id") REFERENCES "public"."yarn_brand_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_detail" ADD CONSTRAINT "transaction_detail_uom_id_uom_master_id_fk" FOREIGN KEY ("uom_id") REFERENCES "public"."uom_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_header" ADD CONSTRAINT "transaction_header_transaction_type_id_transaction_type_master_id_fk" FOREIGN KEY ("transaction_type_id") REFERENCES "public"."transaction_type_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_header" ADD CONSTRAINT "transaction_header_job_id_job_master_id_fk" FOREIGN KEY ("job_id") REFERENCES "public"."job_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_header" ADD CONSTRAINT "transaction_header_party_id_party_master_id_fk" FOREIGN KEY ("party_id") REFERENCES "public"."party_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_header" ADD CONSTRAINT "transaction_header_location_id_location_master_id_fk" FOREIGN KEY ("location_id") REFERENCES "public"."location_master"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "transaction_header" ADD CONSTRAINT "transaction_header_fabric_type_id_fabric_type_master_id_fk" FOREIGN KEY ("fabric_type_id") REFERENCES "public"."fabric_type_master"("id") ON DELETE no action ON UPDATE no action;