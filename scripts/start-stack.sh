#!/usr/bin/env bash
# Start PostgreSQL + NestJS backend (Docker Compose).
# Usage from repo root:
#   ./scripts/start-stack.sh          # dev: hot reload + published DB port
#   ./scripts/start-stack.sh prod     # production image, no bind mount
#   ./scripts/start-stack.sh down     # stop containers

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is not installed or not on PATH." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Error: docker compose plugin is required." >&2
  exit 1
fi

ensure_env() {
  if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "Created .env from .env.example"
  fi
  if [[ ! -f backend/.env ]]; then
    cp backend/.env.example backend/.env
    echo "Created backend/.env from backend/.env.example"
  fi
}

MODE="${1:-dev}"

case "$MODE" in
  db|postgres)
    ensure_env
    echo "Starting PostgreSQL only (port \${POSTGRES_PUBLISH_PORT:-5432} → host)…"
    echo "Then from backend/: npm run start:dev  OR  npm run prisma:migrate"
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d postgres
    echo "Waiting for Postgres healthcheck…"
    docker compose -f docker-compose.yml -f docker-compose.dev.yml ps postgres
    ;;
  down|stop)
    docker compose -f docker-compose.yml -f docker-compose.dev.yml down
    echo "Stack stopped."
    ;;
  prod|production)
    ensure_env
    echo "Starting PostgreSQL + backend (production)…"
    echo "  API:    http://localhost:3000/api/v1/health"
    echo "  Swagger http://localhost:3000/docs"
    docker compose up --build
    ;;
  dev|""|*)
    ensure_env
    echo "Starting PostgreSQL + backend (development)…"
    echo "  API:     http://localhost:3000/api/v1/health"
    echo "  Swagger: http://localhost:3000/docs"
    echo "  Postgres on host: 127.0.0.1:\${POSTGRES_PUBLISH_PORT:-5432}"
    echo ""
    echo "  Local Nest only: npm run db  then  cd backend && npm run start:dev"
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
    ;;
esac
