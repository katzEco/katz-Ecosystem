#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

mkdir -p "${BACKUP_DIR}"

echo "📦 Dumping databases..."
echo "────────────────────────────────────────"

# Check postgres running
if ! docker compose ps db_postgres_eco | grep -q "Up"; then
  echo "❌ Error: db_postgres_eco is not running. Start with 'make up db'"
  exit 1
fi

# 1. PostgreSQL dump
echo "🐘 Dumping PostgreSQL database..."
SQL_LATEST="${BACKUP_DIR}/postgres_backup.sql"
SQL_STAMPED="${BACKUP_DIR}/postgres_${TIMESTAMP}.sql"

docker compose exec -T db_postgres_eco sh -c \
  'pg_dump -U $POSTGRES_USER -d $POSTGRES_DB --clean --if-exists --no-owner --no-privileges' > "${SQL_LATEST}"
cp "${SQL_LATEST}" "${SQL_STAMPED}"

echo "   ✔ Saved: ${SQL_LATEST}"
echo "   ✔ Archived: ${SQL_STAMPED}"

# 2. Redis dump
if docker compose ps db_redis_eco | grep -q "Up"; then
  echo "🔴 Saving Redis snapshot..."
  RDB_LATEST="${BACKUP_DIR}/redis_dump.rdb"
  RDB_STAMPED="${BACKUP_DIR}/redis_${TIMESTAMP}.rdb"
  AOF_LATEST="${BACKUP_DIR}/redis_appendonly.tar.gz"

  docker compose exec -T db_redis_eco redis-cli save > /dev/null
  docker compose cp db_redis_eco:/data/dump.rdb "${RDB_LATEST}"
  cp "${RDB_LATEST}" "${RDB_STAMPED}"
  docker compose exec -T db_redis_eco tar -czf - -C /data appendonlydir > "${AOF_LATEST}" 2>/dev/null || true

  echo "   ✔ Saved Redis: ${RDB_LATEST}"
fi

echo "────────────────────────────────────────"
echo "✅ Dump complete! Files in backups/:"
ls -lh "${BACKUP_DIR}"
