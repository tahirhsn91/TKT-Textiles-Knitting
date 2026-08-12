-- FBR Invoicing: add a dedicated business invoice number, independent of the
-- DB id. The next generated invoice takes number 000255 (per requirement).
-- Implemented as a Postgres sequence (invoice_number_seq) starting at 254 so
-- the first nextval() returns 255. Existing rows keep a NULL invoice_number
-- (backfilled by the next generation if needed).
--> statement-breakpoint

ALTER TABLE "invoice" ADD COLUMN IF NOT EXISTS "invoice_number" integer;

-- Sequence for assigning invoice numbers. Start at 254 so the first nextval()
-- yields 255 (the requested next invoice number).
CREATE SEQUENCE IF NOT EXISTS "invoice_number_seq" START WITH 254;
--> statement-breakpoint
SELECT setval('invoice_number_seq', 254, true);
