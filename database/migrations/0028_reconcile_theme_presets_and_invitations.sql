-- Migration: 0028_reconcile_theme_presets_and_invitations
-- Purpose: Repair two tables where stale migrations (0023/0025) created a
-- schema diverging from the Drizzle source of truth, and 0027's
-- CREATE TABLE IF NOT EXISTS was a no-op because the tables already existed:
--   * theme_presets     — missing navbar/sidebar color columns (0023 omitted
--     them; the backend queries them -> 500 on GET /api/branding/package)
--   * user_invitations  — outdated shape (role_id/role_name/invitation_code/
--     invitation_token/expired_at/accepted_by_user_id) vs Drizzle
--     (role/token/accepted_by/expires_at)
-- Idempotent: safe to run on DBs that are already correct — all ALTERs use
-- IF EXISTS / IF NOT EXISTS and the legacy-column block is guarded.
-- Date: 2026-08-26

BEGIN;

-- ── 1. theme_presets: add the columns the backend queries (matches Drizzle) ─
ALTER TABLE theme_presets
  ADD COLUMN IF NOT EXISTS navbar_color TEXT,
  ADD COLUMN IF NOT EXISTS navbar_text_color TEXT,
  ADD COLUMN IF NOT EXISTS sidebar_color TEXT,
  ADD COLUMN IF NOT EXISTS sidebar_text_color TEXT,
  ADD COLUMN IF NOT EXISTS accent_hover_color TEXT;

-- ── 2. user_invitations: align with the Drizzle schema ──────────────────────
-- Add the columns the code expects (no-op if already present).
ALTER TABLE user_invitations ADD COLUMN IF NOT EXISTS role TEXT;
ALTER TABLE user_invitations ADD COLUMN IF NOT EXISTS token TEXT;
ALTER TABLE user_invitations ADD COLUMN IF NOT EXISTS accepted_by INTEGER;
ALTER TABLE user_invitations ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP;

-- Backfill from the legacy shape (if it exists), then drop legacy columns.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_invitations' AND column_name = 'invitation_token'
  ) THEN
    UPDATE user_invitations SET
      role        = COALESCE(role_name, 'Manager'),
      token       = COALESCE(invitation_token, token),
      status      = COALESCE(status, 'pending'),
      accepted_by = COALESCE(accepted_by_user_id, accepted_by),
      expires_at  = COALESCE(expired_at, expires_at);
    ALTER TABLE user_invitations
      DROP COLUMN IF EXISTS role_id,
      DROP COLUMN IF EXISTS role_name,
      DROP COLUMN IF EXISTS invitation_code,
      DROP COLUMN IF EXISTS invitation_token,
      DROP COLUMN IF EXISTS expired_at,
      DROP COLUMN IF EXISTS accepted_by_user_id;
  END IF;
END $$;

-- Enforce Drizzle defaults / nullability.
ALTER TABLE user_invitations ALTER COLUMN role SET DEFAULT 'Manager';
ALTER TABLE user_invitations ALTER COLUMN role SET NOT NULL;
ALTER TABLE user_invitations ALTER COLUMN token SET NOT NULL;
ALTER TABLE user_invitations ALTER COLUMN status SET DEFAULT 'pending';
ALTER TABLE user_invitations ALTER COLUMN status SET NOT NULL;

-- Indexes matching the Drizzle schema / 0027.
CREATE INDEX IF NOT EXISTS idx_invitations_tenant ON user_invitations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON user_invitations(status);

COMMIT;
