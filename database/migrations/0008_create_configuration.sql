-- System configuration table.
-- Read-only from the UI and API: records are created/updated/deleted only via
-- database migration. The API exposes GET only (no write routes).
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "configuration" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"code" text NOT NULL,
	"description" text,
	"enabled" boolean DEFAULT true NOT NULL,
	CONSTRAINT "configuration_code_unique" UNIQUE("code")
);
