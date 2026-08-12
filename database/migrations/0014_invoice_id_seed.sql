-- FBR Invoicing: seed the invoice table's id sequence so the next generated
-- invoice takes the id 255 (displayed as "000255" via the padded id). This
-- keeps the invoice number equal to the row id — no separate column needed.
--> statement-breakpoint

-- Highest existing invoice id + 254 → nextval returns 255.
SELECT setval(pg_get_serial_sequence('invoice', 'id'), GREATEST((SELECT COALESCE(MAX(id), 0) FROM invoice), 254), true);
