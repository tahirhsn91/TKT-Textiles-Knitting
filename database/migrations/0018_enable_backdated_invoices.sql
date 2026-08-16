-- Enable the "Allow Backdated Invoices" toggle (issue #189 / code 0003).
--
-- 0017 seeded the toggle as disabled (default false). This flips it on so the
-- "Create Backdated Invoice" tool is available in the invoicing page.
-- Idempotent: UPDATE is safe to re-run; only affects the 0003 row.
--> statement-breakpoint
UPDATE "configuration" SET "enabled" = true WHERE "code" = '0003';
