-- Self-tuning statistical validator for the daily operations.
-- Two tables:
--   plausibility_baseline  — the learned distribution (median/IQR/MAD + warn
--                            bounds) per (operation, field). Recomputed
--                            incrementally on insert and rebuildable via
--                            POST /api/plausibility/retrain.
--   plausibility_feedback  — the learning signal: what an operator did with a
--                            value they were warned about (kept it / corrected).
-- Warn-only feature: nothing here blocks or edits operational data.
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "plausibility_baseline" (
	"id" serial PRIMARY KEY NOT NULL,
	"operation" text NOT NULL,
	"field" text NOT NULL,
	"median" numeric(18, 6) NOT NULL,
	"iqr" numeric(18, 6) NOT NULL,
	"mad" numeric(18, 6) NOT NULL,
	"lower_bound" numeric(18, 6) NOT NULL,
	"upper_bound" numeric(18, 6) NOT NULL,
	"sample_count" integer DEFAULT 0 NOT NULL,
	"computed_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "plausibility_baseline_operation_field_unique" UNIQUE("operation","field")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "plausibility_feedback" (
	"id" serial PRIMARY KEY NOT NULL,
	"operation" text NOT NULL,
	"field" text NOT NULL,
	"entered_value" numeric(18, 6) NOT NULL,
	"expected_low" numeric(18, 6),
	"expected_high" numeric(18, 6),
	"outcome" text NOT NULL,
	"created_by" text,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "plausibility_feedback_operation_field_idx" ON "plausibility_feedback" ("operation","field");
