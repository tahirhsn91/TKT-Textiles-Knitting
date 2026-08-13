-- User Management & RBAC (issue #135)
-- New tables: role (fixed/seeded roles), role_permission (route-level per-role
-- permissions), app_user (auth accounts; optionally linked to an employee).
-- Seeds: the 3 roles (Admin, Manager, Supervisor) and the default admin user
-- (username "admin"). All seeds are idempotent (ON CONFLICT DO NOTHING).
--> statement-breakpoint

-- ─── Roles ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "role" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"is_admin" boolean DEFAULT false NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "role_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "role_name_idx" ON "role" USING btree ("name");

-- ─── Route-level permissions per role ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS "role_permission" (
	"role_id" integer NOT NULL,
	"module_id" text NOT NULL,
	CONSTRAINT "role_permission_role_id_role_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."role"("id") ON DELETE cascade ON UPDATE no action,
	CONSTRAINT "role_permission_role_id_module_id_pk" PRIMARY KEY("role_id","module_id")
);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "role_permission_role_idx" ON "role_permission" USING btree ("role_id");

-- ─── Users ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "app_user" (
	"id" serial PRIMARY KEY NOT NULL,
	"username" text NOT NULL,
	"display_name" text NOT NULL,
	"password_hash" text NOT NULL,
	"role_id" integer NOT NULL,
	"employee_id" integer,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "app_user_role_id_role_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."role"("id") ON DELETE no action ON UPDATE no action,
	CONSTRAINT "app_user_employee_id_employee_master_id_fk" FOREIGN KEY ("employee_id") REFERENCES "public"."employee_master"("id") ON DELETE no action ON UPDATE no action,
	CONSTRAINT "app_user_username_unique" UNIQUE("username")
);
--> statement-breakpoint
CREATE UNIQUE INDEX IF NOT EXISTS "user_username_idx" ON "app_user" USING btree ("username");

-- ─── Seed: roles (idempotent) ──────────────────────────────────────────────
INSERT INTO "role" ("name", "is_admin") VALUES ('Admin', true) ON CONFLICT ("name") DO NOTHING;
--> statement-breakpoint
INSERT INTO "role" ("name", "is_admin") VALUES ('Manager', false) ON CONFLICT ("name") DO NOTHING;
--> statement-breakpoint
INSERT INTO "role" ("name", "is_admin") VALUES ('Supervisor', false) ON CONFLICT ("name") DO NOTHING;
