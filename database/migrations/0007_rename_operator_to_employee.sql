-- Rename Operator concept to Employee across the schema.
-- Tables: machine_operator_master -> employee_master
--         operator_advances -> employee_advances
--         operator_salary_records -> employee_salary_records
--         operator_salary_settings -> employee_salary_settings
-- Columns: operator_id -> employee_id (all referencing tables)
--          operator_name -> employee_name (salary_detail)
--          machine_operator_id -> employee_id (transaction_detail)
--> statement-breakpoint
ALTER TABLE "machine_operator_master" RENAME TO "employee_master";--> statement-breakpoint
ALTER TABLE "operator_advances" RENAME TO "employee_advances";--> statement-breakpoint
ALTER TABLE "operator_salary_records" RENAME TO "employee_salary_records";--> statement-breakpoint
ALTER TABLE "operator_salary_settings" RENAME TO "employee_salary_settings";--> statement-breakpoint
ALTER TABLE "employee_advances" RENAME COLUMN "operator_id" TO "employee_id";--> statement-breakpoint
ALTER TABLE "employee_salary_records" RENAME COLUMN "operator_id" TO "employee_id";--> statement-breakpoint
ALTER TABLE "employee_salary_settings" RENAME COLUMN "operator_id" TO "employee_id";--> statement-breakpoint
ALTER TABLE "salary_detail" RENAME COLUMN "operator_id" TO "employee_id";--> statement-breakpoint
ALTER TABLE "salary_detail" RENAME COLUMN "operator_name" TO "employee_name";--> statement-breakpoint
ALTER TABLE "daily_production_header" RENAME COLUMN "operator_id" TO "employee_id";--> statement-breakpoint
ALTER TABLE "transaction_detail" RENAME COLUMN "machine_operator_id" TO "employee_id";--> statement-breakpoint
ALTER TABLE "employee_master" RENAME CONSTRAINT "machine_operator_master_code_unique" TO "employee_master_code_unique";--> statement-breakpoint
ALTER TABLE "employee_advances" RENAME CONSTRAINT "operator_advances_operator_id_machine_operator_master_id_fk" TO "employee_advances_employee_id_employee_master_id_fk";--> statement-breakpoint
ALTER TABLE "employee_salary_records" RENAME CONSTRAINT "operator_salary_records_operator_id_machine_operator_master_id_fk" TO "employee_salary_records_employee_id_employee_master_id_fk";--> statement-breakpoint
ALTER TABLE "employee_salary_records" RENAME CONSTRAINT "operator_salary_records_operator_id_date_unique" TO "employee_salary_records_employee_id_date_unique";--> statement-breakpoint
ALTER TABLE "employee_salary_settings" RENAME CONSTRAINT "operator_salary_settings_operator_id_machine_operator_master_id_fk" TO "employee_salary_settings_employee_id_employee_master_id_fk";--> statement-breakpoint
ALTER TABLE "employee_salary_settings" RENAME CONSTRAINT "operator_salary_settings_operator_id_unique" TO "employee_salary_settings_employee_id_unique";--> statement-breakpoint
ALTER TABLE "salary_detail" RENAME CONSTRAINT "salary_detail_operator_id_machine_operator_master_id_fk" TO "salary_detail_employee_id_employee_master_id_fk";--> statement-breakpoint
ALTER TABLE "salary_detail" RENAME CONSTRAINT "salary_detail_header_operator_unique" TO "salary_detail_header_employee_unique";--> statement-breakpoint
ALTER TABLE "salary_detail" RENAME CONSTRAINT "salary_detail_op_month_year_unique" TO "salary_detail_emp_month_year_unique";--> statement-breakpoint
ALTER TABLE "daily_production_header" RENAME CONSTRAINT "daily_production_header_operator_id_machine_operator_master_id_fk" TO "daily_production_header_employee_id_employee_master_id_fk";--> statement-breakpoint
ALTER TABLE "transaction_detail" RENAME CONSTRAINT "transaction_detail_machine_operator_id_machine_operator_master_id_fk" TO "transaction_detail_employee_id_employee_master_id_fk";
--> statement-breakpoint
ALTER TABLE "employee_master" RENAME CONSTRAINT "machine_operator_master_pkey" TO "employee_master_pkey";--> statement-breakpoint
ALTER TABLE "employee_advances" RENAME CONSTRAINT "operator_advances_pkey" TO "employee_advances_pkey";--> statement-breakpoint
ALTER TABLE "employee_salary_records" RENAME CONSTRAINT "operator_salary_records_pkey" TO "employee_salary_records_pkey";--> statement-breakpoint
ALTER TABLE "employee_salary_settings" RENAME CONSTRAINT "operator_salary_settings_pkey" TO "employee_salary_settings_pkey";
