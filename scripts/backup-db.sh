#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/deploy/project/tkt-textiles-prod/app"
COMPOSE_PROJECT="tkt-textiles-prod"
BACKUP_FILE="database/backup.sql"

# Use Pakistan time for the branch name (02:00 AM PKT = next day in PKT)
BRANCH_DATE=$(TZ='Asia/Karachi' date +%d-%m-%Y)
BRANCH_NAME="backup/${BRANCH_DATE}"

echo "[$(date '+%Y-%m-%d %H:%M:%S UTC')] Starting DB backup..."
echo "Branch: $BRANCH_NAME"

cd "$PROJECT_DIR"

# On any exit (success or failure): return to main and restore any stash.
cleanup() {
  git checkout main 2>/dev/null || true
  git stash pop 2>/dev/null || true
}
trap cleanup EXIT

# Stash local TRACKED changes BEFORE dumping, so switching branches cannot
# carry local edits into the backup branch.
# IMPORTANT: stash BEFORE the dump and do NOT use --include-untracked.
#   - Stashing after the dump used to swallow the fresh backup.sql itself,
#     so the commit step found "no changes" and exited 0 silently
#     (the backup/06-08-2026 incident — dump created but never committed).
#   - --include-untracked used to swallow logs/ (including the cron log
#     file being appended to right now), deleting it from disk mid-run.
git stash push -m "backup-pre-stash-${BRANCH_DATE}" 2>/dev/null || true

# Dump the production database
echo "Dumping heliumdb_prod..."
docker exec "${COMPOSE_PROJECT}-postgres-1" pg_dump -U postgres -d heliumdb_prod --no-owner --no-acl > "/tmp/backup_${BRANCH_DATE}.sql"

# Copy to repo and overwrite existing
cp "/tmp/backup_${BRANCH_DATE}.sql" "$PROJECT_DIR/$BACKUP_FILE"
rm "/tmp/backup_${BRANCH_DATE}.sql"

FILE_SIZE=$(du -h "$PROJECT_DIR/$BACKUP_FILE" | cut -f1)
echo "Backup size: $FILE_SIZE"

# Create or reset the backup branch
if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
  echo "Branch $BRANCH_NAME exists, resetting..."
  git checkout main
  git branch -D "$BRANCH_NAME"
fi

git checkout -b "$BRANCH_NAME"

# Commit and push
git add "$BACKUP_FILE"
git commit -m "Daily backup: ${BRANCH_DATE}" || {
  echo "No changes to commit (backup identical to previous?)"
  exit 0
}

echo "Pushing to origin..."
git push origin "$BRANCH_NAME" --force

echo "[$(date '+%Y-%m-%d %H:%M:%S UTC')] Backup complete. Branch: $BRANCH_NAME"
