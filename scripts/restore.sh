#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"

SQL_FILE="${1:-${BACKUP_DIR}/postgres_backup.sql}"

if [ ! -f "${SQL_FILE}" ]; then
  echo "❌ Error: Backup file not found: ${SQL_FILE}"
  exit 1
fi

echo "📦 Restoring databases..."
echo "────────────────────────────────────────"

if ! docker compose ps db_postgres_eco | grep -q "Up"; then
  echo "❌ Error: db_postgres_eco is not running. Start with 'make up db'"
  exit 1
fi

echo "🐘 Restoring PostgreSQL from ${SQL_FILE}..."
docker compose exec -T db_postgres_eco sh -c \
  'psql -U $POSTGRES_USER -d $POSTGRES_DB' < "${SQL_FILE}"
echo "   ✔ PostgreSQL restored."

if [ -f "${BACKUP_DIR}/redis_dump.rdb" ] && docker compose ps db_redis_eco | grep -q "Up"; then
  echo "🔴 Restoring Redis snapshot..."
  docker compose stop db_redis_eco
  docker compose cp "${BACKUP_DIR}/redis_dump.rdb" db_redis_eco:/data/dump.rdb
  docker compose start db_redis_eco
  echo "   ✔ Redis restored."
fi

echo "────────────────────────────────────────"
echo "✅ Database restore complete!"
