#!/usr/bin/env bash
# DEV CORS origins watchdog — run from cron every 10 minutes.
# If the dev backend container's ALLOWED_ORIGINS drifts (e.g. after a compose
# up that picked a stale/prod env file), recreate the backend with the correct
# dev .env and log the event. Mirrors the prod watchdog pattern.
set -uo pipefail

COMPOSE_PROJECT="tkt-textiles-knitting"
APP_DIR="/home/deploy/project/TKT-Textiles-Knitting"
EXPECTED="169.58.108.61:3001"
LOG="${APP_DIR}/logs/origins-watchdog-dev.log"

mkdir -p "$(dirname "$LOG")"

current=$(docker exec "${COMPOSE_PROJECT}-backend-1" printenv ALLOWED_ORIGINS 2>/dev/null || echo "UNKNOWN")

# Healthy — nothing to do
if echo "$current" | grep -q "$EXPECTED"; then
  exit 0
fi

echo "[$(date -u '+%F %T UTC')] DRIFT DETECTED: ALLOWED_ORIGINS='$current'. Recreating dev backend with correct .env..." >> "$LOG"

cd "$APP_DIR"
docker compose -f docker-compose.yml -f docker-compose.dev.yml --env-file .env -p "$COMPOSE_PROJECT" up -d backend >> "$LOG" 2>&1

sleep 5
current=$(docker exec "${COMPOSE_PROJECT}-backend-1" printenv ALLOWED_ORIGINS 2>/dev/null || echo "UNKNOWN")
if echo "$current" | grep -q "$EXPECTED"; then
  echo "[$(date -u '+%F %T UTC')] FIXED: ALLOWED_ORIGINS='$current'" >> "$LOG"
else
  echo "[$(date -u '+%F %T UTC')] FIX FAILED: ALLOWED_ORIGINS='$current'" >> "$LOG"
fi
