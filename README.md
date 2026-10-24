# Katz Eco Infrastructure

Docker Compose setup providing local PostgreSQL and Redis services for the Katz ecosystem.

## Services

| Service        | Image                | Container Name      | Default Port | Persistence                       |
| :------------- | :------------------- | :------------------ | :----------- | :-------------------------------- |
| `postgres_eco` | `postgres:17-alpine` | `postgres_katz-eco` | `5432`       | `postgres_data` volume            |
| `redis_eco`    | `redis:7-alpine`     | `redis_katz-eco`    | `6379`       | `redis_data` volume (AOF enabled) |

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

## Common Commands

- **View logs:** `docker compose logs -f`
- **Stop services:** `docker compose down`
- **Stop and remove volumes (reset data):** `docker compose down -v`
