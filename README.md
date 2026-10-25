# Katz Eco Infrastructure

Docker Compose setup providing local PostgreSQL, Redis, and Todo services for the Katz ecosystem.

## Services

| Service           | Image / Source                    | Container Name        | Default Port | Persistence                            |
| :---------------- | :-------------------------------- | :-------------------- | :----------- | :------------------------------------- |
| `todo`            | `./modules/katz-todo`             | `katz_todo`           | `3000`       | -                                      |
| `live_detector`   | `./modules/katz-live-detector`    | `katz_live_detector`  | `3030`       | -                                      |
| `db_postgres_eco` | `postgres:17-alpine`              | `postgres_katz_eco`   | `5432`       | `katz-pg-data` volume                  |
| `db_redis_eco`    | `redis:7-alpine`                  | `redis_katz_eco`      | `6379`       | `katz-redis-data` volume (AOF enabled) |

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose

## Getting Started

1. Copy the example environment file and adjust values if needed:

   ```bash
   cp .env.example .env
   ```

2. Start the services in the background:

   ```bash
   docker compose up -d
   ```

3. Check service health and status:

   ```bash
   docker compose ps
   ```

## Environment Variables

| Variable            | Description                               | Default    |
| :------------------ | :---------------------------------------- | :--------- |
| `POSTGRES_USER`     | PostgreSQL superuser name                 | `postgres` |
| `POSTGRES_PASSWORD` | PostgreSQL superuser password             | `postgres` |
| `POSTGRES_DB`       | Default database created on startup       | `app`      |
| `POSTGRES_PORT`     | Host port mapped to container port `5432` | `5432`     |
| `REDIS_PORT`        | Host port mapped to container port `6379` | `6379`     |
| `TODO_PORT`               | Host port mapped to container port `3000`           | `3000`                                           |
| `DETECTOR_PORT`           | Host port mapped to container port `3030`           | `3030`                                           |
| `TELEGRAM_TOKEN`          | Optional Telegram bot token                         | `""`                                             |
| `DISCORD_TOKEN`           | Optional Discord bot token                          | `""`                                             |
| `TELEGRAM_ADMIN_ID`       | Optional initial Telegram Admin ID for whitelist    | `""`                                             |
| `DISCORD_ADMIN_ID`        | Optional initial Discord Admin ID for whitelist     | `""`                                             |
| `N8N_DEFAULT_WEBHOOK_URL` | Optional default n8n webhook URL for Live Detector  | `""`                                             |
| `CHECK_INTERVAL_SECONDS`  | Live detector poll interval in seconds (min 10)     | `60`                                             |
| `INITIAL_USERNAMES`       | Optional comma-separated TikTok usernames to seed   | `""`                                             |
| `API_KEY`                 | Optional API key to protect Live Detector endpoints | `""`                                             |
| `WEBHOOK_SECRET`          | Optional secret header sent to n8n webhook          | `""`                                             |

## Common Commands

- **View logs:** `docker compose logs -f`
- **Stop services:** `docker compose down`
- **Stop and remove volumes (reset data):** `docker compose down -v`
