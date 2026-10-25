#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"

# Input can be a zip archive or fallback to raw sql file
INPUT="${1:-${BACKUP_DIR}/backup_latest.zip}"

# If default zip not found, check if a raw sql backup exists
if [ ! -f "${INPUT}" ]; then
  if [ -f "${BACKUP_DIR}/postgres_backup.sql" ]; then
    INPUT="${BACKUP_DIR}/postgres_backup.sql"
  else
    echo "❌ Error: Backup file not found: ${INPUT}"
    echo "   Provide a valid zip file, e.g.: ./scripts/restore.sh backups/backup_latest.zip"
    exit 1
  fi
fi

TEMP_DIR=""
cleanup() {
  if [ -n "${TEMP_DIR}" ] && [ -d "${TEMP_DIR}" ]; then
    rm -rf "${TEMP_DIR}"
  fi
}
trap cleanup EXIT

echo "📦 Restoring databases from: ${INPUT}"
echo "────────────────────────────────────────"

# Check postgres running
if ! docker compose ps db_postgres_eco | grep -q "Up"; then
  echo "❌ Error: db_postgres_eco is not running. Start with 'make up db'"
  exit 1
fi

SQL_PATH=""
RDB_PATH=""

# Determine if input is a zip archive or plain file
if [[ "${INPUT}" == *.zip ]]; then
  echo "📂 Extracting zip archive..."
  TEMP_DIR="$(mktemp -d)"
  unzip -q -o "${INPUT}" -d "${TEMP_DIR}"

  # Locate sql file inside zip
  if [ -f "${TEMP_DIR}/postgres_backup.sql" ]; then
    SQL_PATH="${TEMP_DIR}/postgres_backup.sql"
  else
    SQL_PATH="$(find "${TEMP_DIR}" -name "*.sql" | head -n 1)"
  fi

  # Locate redis dump inside zip
  if [ -f "${TEMP_DIR}/redis_dump.rdb" ]; then
    RDB_PATH="${TEMP_DIR}/redis_dump.rdb"
  fi
elif [[ "${INPUT}" == *.sql ]]; then
  SQL_PATH="${INPUT}"
  if [ -f "${BACKUP_DIR}/redis_dump.rdb" ]; then
    RDB_PATH="${BACKUP_DIR}/redis_dump.rdb"
  fi
fi

if [ -z "${SQL_PATH}" ] || [ ! -f "${SQL_PATH}" ]; then
  echo "❌ Error: No SQL dump found inside ${INPUT}"
  exit 1
fi

# 1. Restore PostgreSQL
echo "🐘 Restoring PostgreSQL from ${SQL_PATH}..."
docker compose exec -T db_postgres_eco sh -c \
  'psql -U $POSTGRES_USER -d $POSTGRES_DB' < "${SQL_PATH}"
echo "   ✔ PostgreSQL restored."

# 2. Restore Redis
if [ -n "${RDB_PATH}" ] && [ -f "${RDB_PATH}" ] && docker compose ps db_redis_eco | grep -q "Up"; then
  echo "🔴 Restoring Redis snapshot..."
  docker compose stop db_redis_eco
  docker compose cp "${RDB_PATH}" db_redis_eco:/data/dump.rdb
  docker compose start db_redis_eco
  echo "   ✔ Redis restored."
fi

echo "────────────────────────────────────────"
echo "✅ Database restore complete!"
