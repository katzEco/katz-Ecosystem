# Katz Eco Infrastructure

Docker Compose setup and development harness for the Katz ecosystem services: **Todo**, **Live Detector**, **Utils**, and underlying **PostgreSQL** and **Redis** data stores.

## Services

| Service | Directory / Source | Container Name | Default Port | Persistence / Notes |
| :--- | :--- | :--- | :--- | :--- |
| `todo` | [`./modules/katz-todo`](./modules/katz-todo) | `katz_todo` | `3000` | Web dashboard & Telegram/Discord task bot |
| `live` | [`./modules/katz-live-detector`](./modules/katz-live-detector) | `katz_live_detector` | `3030` | TikTok live detector & n8n webhook dispatcher |
| `utils` | [`./modules/katz-utils`](./modules/katz-utils) | `katz_utils` | `3050` | Chat moderation (`/clean`), telemetry & health API |
| `db_postgres_eco` | `postgres:17-alpine` | `postgres_katz_eco` | `5432` | `katz-pg-data` volume |
| `db_redis_eco` | `redis:7-alpine` | `redis_katz_eco` | `6379` | `katz-redis-data` volume (AOF enabled) |

## Modules Overview

- **[Katz Todo](./modules/katz-todo)**: High-performance task management system built on Hono, native `Bun.SQL`, and `Bun.RedisClient`. Features a brutalist web dashboard, category management, bot command whitelisting, and dual Telegram/Discord bot integrations (`/todo`, `!todo`).
- **[Katz Live Detector](./modules/katz-live-detector)**: Real-time TikTok live monitoring daemon. Tracks creator streams via dual-engine polling, caches stream states in Redis, persists audit logs in PostgreSQL, and dispatches `live_started` / `live_ended` event payloads to an n8n webhook workflow.
- **[Katz Utils](./modules/katz-utils)**: Operational utility bot for Telegram and Discord providing bulk chat purging (`/clean`, `!clean`), roundtrip latency checks (`/ping`), host telemetry (`/info`), and an HTTP health endpoint.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2+
- [Bun](https://bun.sh/) (optional, required only for local module development outside Docker)
- GNU Make (optional, for CLI shortcuts)

## Getting Started

1. **Clone repository with submodules:**

   ```bash
   git clone --recursive https://github.com/katzEco/main-repo.git
   cd main-repo
   ```

   If already cloned without submodules:

   ```bash
   git submodule update --init --recursive
   ```

2. **Configure environment:**

   ```bash
   cp .env.example .env
   ```

   Adjust ports, database credentials, bot tokens, and webhook URLs in `.env` as needed.

3. **Start all services:**

   ```bash
   make up
   # or: docker compose up -d
   ```

4. **Verify container health:**

   ```bash
   make ps
   # or: docker compose ps
   ```

## Environment Variables

### Core & Timezone
| Variable | Description | Default |
| :--- | :--- | :--- |
| `TZ` | Container and database timezone (IANA format) | `Asia/Bangkok` |

### PostgreSQL & Redis
| Variable | Description | Default |
| :--- | :--- | :--- |
| `POSTGRES_USER` | PostgreSQL superuser username | `postgres` |
| `POSTGRES_PASSWORD` | PostgreSQL superuser password | `postgres` |
| `POSTGRES_DB` | Default database created on initialization | `app` |
| `POSTGRES_PORT` | Host port mapped to PostgreSQL (`5432` in container) | `5432` |
| `REDIS_PORT` | Host port mapped to Redis (`6379` in container) | `6379` |

### Todo Service
| Variable | Description | Default |
| :--- | :--- | :--- |
| `TODO_PORT` | Host port mapped to Todo service (`3000` in container) | `3000` |
| `TELEGRAM_TOKEN` | Optional Telegram bot token for Todo bot | `""` |
| `DISCORD_TOKEN` | Optional Discord bot token for Todo bot | `""` |
| `TELEGRAM_ADMIN_ID` | Optional initial Telegram user ID seeded into whitelist | `""` |
| `DISCORD_ADMIN_ID` | Optional initial Discord user ID seeded into whitelist | `""` |

### Live Detector Service
| Variable | Description | Default |
| :--- | :--- | :--- |
| `DETECTOR_PORT` | Host port mapped to Live Detector (`3030` in container) | `3030` |
| `N8N_DEFAULT_WEBHOOK_URL` | Destination n8n webhook URL for stream status events | `""` |
| `CHECK_INTERVAL_SECONDS` | Poll frequency interval in seconds (minimum 10s) | `60` |
| `INITIAL_USERNAMES` | Comma-separated TikTok usernames to register on startup | `""` |
| `API_KEY` | Optional bearer token to protect `/api/*` endpoints | `""` |
| `WEBHOOK_SECRET` | Optional secret token sent in `X-Webhook-Secret` header | `""` |

### Utils Service
| Variable | Description | Default |
| :--- | :--- | :--- |
| `UTILS_PORT` | Host port mapped to Utils service (`3050` in container) | `3050` |
| `UTILS_TELEGRAM_TOKEN` | Optional Telegram bot token for Katz Utils bot | `""` |
| `UTILS_DISCORD_TOKEN` | Optional Discord bot token for Katz Utils bot | `""` |
| `UTILS_TELEGRAM_ADMIN_ID`| Optional Telegram Admin ID override (falls back to `TELEGRAM_ADMIN_ID`) | `""` |
| `UTILS_DISCORD_ADMIN_ID` | Optional Discord Admin ID override (falls back to `DISCORD_ADMIN_ID`) | `""` |

## Common Commands

Manage the stack with `make` shortcuts or standard Docker Compose commands. Pass service names as positional arguments (`make up core`, `make down utils`) or via `m=<module>`:

### Available Modules & Presets
- `core`: `todo` + `live`
- `pro`: `todo` + `live` + `utils`
- `todo`: `katz-todo`
- `live`: `katz-live-detector` (aliases: `detector`, `live_detector`)
- `utils`: `katz-utils`
- `db`: `postgres` + `redis`

### Command Reference

| Action | Make Shortcut | Docker Compose Equivalent |
| :--- | :--- | :--- |
| **Start all services** | `make up` | `docker compose up -d` |
| **Start preset / service** | `make up core` (or `make up utils`) | `docker compose up -d [services]` |
| **Build images** | `make build` (or `make build utils`) | `docker compose build [service]` |
| **Rebuild & restart** | `make rebuild` (or `make rebuild core`) | `docker compose up -d --build [service]` |
| **View running status** | `make ps` (or `make ps todo`) | `docker compose ps [service]` |
| **Tail logs** | `make logs` (or `make logs live`) | `docker compose logs -f [service]` |
| **Stop service / all** | `make stop` (or `make stop utils`) | `docker compose stop [service]` |
| **Restart service / all**| `make restart` (or `make restart core`) | `docker compose restart [service]` |
| **Stop and remove** | `make down` (or `make down utils`) | `docker compose down` / `stop + rm` |
| **Open container shell**| `make shell todo` | `docker compose exec -it [service] sh` |
| **Open psql CLI** | `make shell-db` | `docker compose exec -it db_postgres_eco psql ...` |
| **Dump databases** | `make dump` (or `make backup`) | Dump PostgreSQL & Redis snapshots to `backups/` via `scripts/dump.sh` |
| **Restore databases** | `make restore` (or `make import-db`) | Restore PostgreSQL & Redis from `backups/` via `scripts/restore.sh` |
| **Reset all data volumes**| `make clean` | `docker compose down -v` |
| **Show all make targets**| `make help` | - |

## Database Migration (Between Devices)

### On Source Device
Dump databases to a self-contained `.zip` package:

```bash
make dump
# or: ./scripts/dump.sh
```

This creates:
- `backups/backup_latest.zip` (symlinked/copied for easy restore)
- `backups/backup_YYYYMMDD_HHMMSS.zip` (timestamped archive)

Each zip contains:
- `postgres_backup.sql`: Full schema and table data (`api_whitelist`, `categories`, `monitors`, `todo_items`, `webhook_logs`).
- `redis_dump.rdb`: Redis snapshot dump.
- `redis_appendonly.tar.gz`: Redis AOF directory archive.
- `metadata.json`: Timestamp and payload manifest.

### On Target Device
1. Transfer `backups/backup_latest.zip` (or timestamped zip) and `.env` to target device.
2. Start the database containers:
   ```bash
   make up db
   ```
3. Restore from the zip package:
   ```bash
   # Restore default (backups/backup_latest.zip)
   make restore

   # Or specify a particular zip file:
   make restore backups/backup_20261025_213311.zip
   # or: ./scripts/restore.sh backups/backup_20261025_213311.zip
   ```
4. Start the application services:
   ```bash
   make up
   ```
