-- Seed the first system configuration record: "Reconciled lock".
-- Records are only ever added via migration (the UI and API are read-only for
-- this table). Idempotent: `ON CONFLICT (code) DO NOTHING` so re-runs don't
-- duplicate code '0001'.
--> statement-breakpoint
INSERT INTO "configuration" ("name", "code", "description", "enabled")
VALUES ('Reconciled lock', '0001', 'used to enable/disable Reconciliation lock in daily operations', true)
ON CONFLICT ("code") DO NOTHING;
