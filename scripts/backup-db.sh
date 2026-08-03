#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/deploy/project/TKT-Textiles-Knitting"
COMPOSE_PROJECT="tkt-textiles-prod"
BACKUP_FILE="database/backup.sql"

# Use Pakistan time for the branch name (02:00 AM PKT = next day in PKT)
BRANCH_DATE=$(TZ='Asia/Karachi' date +%d-%m-%Y)
BRANCH_NAME="backup/${BRANCH_DATE}"

echo "[$(date '+%Y-%m-%d %H:%M:%S UTC')] Starting DB backup..."
echo "Branch: $BRANCH_NAME"

cd "$PROJECT_DIR"

# Dump the production database
echo "Dumping heliumdb_prod..."
docker exec "${COMPOSE_PROJECT}-postgres-1" pg_dump -U postgres -d heliumdb_prod --no-owner --no-acl > "/tmp/backup_${BRANCH_DATE}.sql"

# Copy to repo and overwrite existing
cp "/tmp/backup_${BRANCH_DATE}.sql" "$PROJECT_DIR/$BACKUP_FILE"
rm "/tmp/backup_${BRANCH_DATE}.sql"

FILE_SIZE=$(du -h "$PROJECT_DIR/$BACKUP_FILE" | cut -f1)
echo "Backup size: $FILE_SIZE"

# Stash any local changes before switching branches
git stash --include-untracked 2>/dev/null || true

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
  git checkout main
  exit 0
}

echo "Pushing to origin..."
git push origin "$BRANCH_NAME" --force

# Return to main
git checkout main

# Restore stashed changes if any
git stash pop 2>/dev/null || true

echo "[$(date '+%Y-%m-%d %H:%M:%S UTC')] Backup complete. Branch: $BRANCH_NAME"
