#!/bin/sh
set -e

LOG_DIR="/root/logs"
LOG_FILE="$LOG_DIR/nest.log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

echo "=== NestJS Startup ===" >> "$LOG_FILE"
echo "Time: $(date)" >> "$LOG_FILE"
echo "DB_HOST: ${DB_HOST:-localhost}" >> "$LOG_FILE"
echo "DB_PORT: ${DB_PORT:-5432}" >> "$LOG_FILE"
echo "PORT: ${PORT:-3050}" >> "$LOG_FILE"

# Wait for PostgreSQL
echo "Waiting for PostgreSQL..." >> "$LOG_FILE"
MAX_RETRIES=30
RETRY_COUNT=0

apk add --no-cache netcat-openbsd 2>/dev/null || true

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if nc -z "${DB_HOST:-localhost}" "${DB_PORT:-5432}" 2>/dev/null; then
    echo "PostgreSQL ready!" >> "$LOG_FILE"
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "Retry $RETRY_COUNT/$MAX_RETRIES..." >> "$LOG_FILE"
  sleep 2
done

# Install dependencies & build
echo "npm install..." >> "$LOG_FILE"
npm install

echo "npm run build..." >> "$LOG_FILE"
npm run build

# Start NestJS
echo "Starting NestJS..." >> "$LOG_FILE"
exec node dist/main.js
