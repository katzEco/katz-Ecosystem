#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
TEMP_DIR="$(mktemp -d)"

trap 'rm -rf "${TEMP_DIR}"' EXIT

mkdir -p "${BACKUP_DIR}"

echo "📦 Dumping databases to zip..."
echo "────────────────────────────────────────"

# Check postgres running
if ! docker compose ps db_postgres_eco | grep -q "Up"; then
  echo "❌ Error: db_postgres_eco is not running. Start with 'make up db'"
  exit 1
fi

# 1. PostgreSQL dump
echo "🐘 Dumping PostgreSQL database..."
docker compose exec -T db_postgres_eco sh -c \
  'pg_dump -U $POSTGRES_USER -d $POSTGRES_DB --clean --if-exists --no-owner --no-privileges' > "${TEMP_DIR}/postgres_backup.sql"
echo "   ✔ PostgreSQL dumped."

# 2. Redis dump
if docker compose ps db_redis_eco | grep -q "Up"; then
  echo "🔴 Saving Redis snapshot..."
  docker compose exec -T db_redis_eco redis-cli save > /dev/null
  docker compose cp db_redis_eco:/data/dump.rdb "${TEMP_DIR}/redis_dump.rdb"
  docker compose exec -T db_redis_eco tar -czf - -C /data appendonlydir > "${TEMP_DIR}/redis_appendonly.tar.gz" 2>/dev/null || true
  echo "   ✔ Redis dumped."
fi

# 3. Create metadata
cat <<EOF > "${TEMP_DIR}/metadata.json"
{
  "timestamp": "${TIMESTAMP}",
  "date": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "postgres": "postgres_backup.sql",
  "redis": "redis_dump.rdb"
}
EOF

# 4. Package into zip
ZIP_LATEST="${BACKUP_DIR}/backup_latest.zip"
ZIP_STAMPED="${BACKUP_DIR}/backup_${TIMESTAMP}.zip"

(cd "${TEMP_DIR}" && zip -q -r "${ZIP_STAMPED}" .)
cp "${ZIP_STAMPED}" "${ZIP_LATEST}"

# Also maintain raw sql copy for convenience
cp "${TEMP_DIR}/postgres_backup.sql" "${BACKUP_DIR}/postgres_backup.sql"
if [ -f "${TEMP_DIR}/redis_dump.rdb" ]; then
  cp "${TEMP_DIR}/redis_dump.rdb" "${BACKUP_DIR}/redis_dump.rdb"
fi

echo "   ✔ Archive created: ${ZIP_STAMPED}"
echo "   ✔ Updated latest:  ${ZIP_LATEST}"
echo "────────────────────────────────────────"
echo "✅ Dump complete! Files in backups/:"
ls -lh "${BACKUP_DIR}"/*.zip
