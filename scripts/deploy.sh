#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="/home/deploy/project/tkt-textiles-prod/app"
COMPOSE_PROJECT="tkt-textiles-prod"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting deploy..."

cd "$PROJECT_DIR"

# Pull latest code
echo "Pulling latest from main..."
git checkout main
git pull origin main

# Rebuild and restart containers
echo "Rebuilding containers..."
docker compose --env-file .env.prod -p "$COMPOSE_PROJECT" build --no-cache
docker compose --env-file .env.prod -p "$COMPOSE_PROJECT" up -d

# Wait for healthy
echo "Waiting for backend to be healthy..."
for i in $(seq 1 30); do
  if docker exec "${COMPOSE_PROJECT}-backend-1" node -e "fetch('http://localhost:8080/api/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))" 2>/dev/null; then
    echo "Backend healthy!"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

# Quick frontend check
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1001)
echo "Frontend HTTP status: $HTTP_CODE"

# Clean up old images
echo "Pruning old images..."
docker image prune -af --filter "until=24h" 2>/dev/null || true

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deploy complete."
