-- Seed: backfill machine_history with a baseline "created" row per machine
-- that already exists in machine_master (history tracking begins now). Each
-- row snapshots the machine's current state, attributed to 'system'.
--
-- Idempotent: the backfill only runs while machine_history is empty, so
-- re-running migrations never duplicates the seed (matches the repo's
-- seed-migration convention — see 0009_seed_configuration.sql).

--> statement-breakpoint

INSERT INTO "machine_history" (
	"machine_id",
	"machine_number",
	"name",
	"making_rate",
	"needle_change_date",
	"needle_brand",
	"sinker_change_date",
	"sinker_brand",
	"action",
	"changed_by"
)
SELECT
	"id",
	"machine_number",
	"name",
	"making_rate",
	"needle_change_date",
	"needle_brand",
	"sinker_change_date",
	"sinker_brand",
	'created',
	'system'
FROM "machine_master"
WHERE NOT EXISTS (SELECT 1 FROM "machine_history");
