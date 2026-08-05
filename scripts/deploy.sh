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

# Verify ALLOWED_ORIGINS is correct — fail loudly instead of deploying broken CORS
REQUIRED_ORIGIN="http://169.58.108.61:1001"
ACTUAL_ORIGINS=$(docker exec "${COMPOSE_PROJECT}-backend-1" printenv ALLOWED_ORIGINS 2>/dev/null || echo "MISSING")
if ! echo "$ACTUAL_ORIGINS" | grep -q "$REQUIRED_ORIGIN"; then
  echo "ERROR: ALLOWED_ORIGINS missing required origin '$REQUIRED_ORIGIN'"
  echo "Got: $ACTUAL_ORIGINS"
  echo "Fix .env.prod and redeploy."
  exit 1
fi
echo "ALLOWED_ORIGINS OK: $ACTUAL_ORIGINS"

# Verify DB schema matches migrations — fail loudly instead of deploying broken features
# (prevents the yarn-receipt incident: code deployed but tables missing in heliumdb_prod)
echo "Verifying DB schema against migrations..."
EXPECTED_TABLES=$(grep -hoP 'CREATE TABLE (?:IF NOT EXISTS )?"\K[^"]+' "$PROJECT_DIR/database/migrations"/*.sql 2>/dev/null | sort -u)
# Tables renamed by later migrations (e.g. machine_operator_master -> employee_master)
# no longer exist under their old names — swap the pre-rename names for the new ones.
RENAMED_AWAY=$(grep -hoP 'ALTER TABLE "\K[^"]+(?=" RENAME TO)' "$PROJECT_DIR/database/migrations"/*.sql 2>/dev/null | sort -u)
RENAMED_TO=$(grep -hoP 'ALTER TABLE "[^"]+" RENAME TO "\K[^"]+' "$PROJECT_DIR/database/migrations"/*.sql 2>/dev/null | sort -u)
if [ -n "$RENAMED_AWAY" ]; then
  EXPECTED_TABLES=$(comm -23 <(echo "$EXPECTED_TABLES" | tr ' ' '\n' | sort -u) <(echo "$RENAMED_AWAY" | sort -u))
  EXPECTED_TABLES=$(printf '%s\n%s\n' "$EXPECTED_TABLES" "$RENAMED_TO" | sort -u)
fi
MISSING=""
for t in $EXPECTED_TABLES; do
  EXISTS=$(docker exec "${COMPOSE_PROJECT}-postgres-1" psql -U postgres -d heliumdb_prod -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='$t'" 2>/dev/null)
  if [ "$EXISTS" != "1" ]; then
    MISSING="$MISSING $t"
  fi
done
if [ -n "$MISSING" ]; then
  echo "ERROR: tables missing in heliumdb_prod:$MISSING"
  echo "Apply the pending migration first, e.g.:"
  echo "  docker compose --env-file .env.prod -p ${COMPOSE_PROJECT} exec -T backend npx drizzle-kit push"
  echo "(or apply the SQL in database/migrations manually to heliumdb_prod)"
  exit 1
fi
echo "DB schema OK: all $(echo $EXPECTED_TABLES | wc -w) migration tables present"

# Quick frontend check
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:1001)
echo "Frontend HTTP status: $HTTP_CODE"

# Clean up old images
echo "Pruning old images..."
docker image prune -af --filter "until=24h" 2>/dev/null || true

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deploy complete."
