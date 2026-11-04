-- Migration: 0030_employee_advances_created_by
-- Purpose: Advances history shows who created each entry. Store a snapshot of
-- the creator's display name on the row (null for pre-existing rows).
-- Idempotent: ADD COLUMN IF NOT EXISTS.
-- Date: 2026-11-04

BEGIN;

ALTER TABLE "employee_advances" ADD COLUMN IF NOT EXISTS "created_by" text;

COMMIT;
