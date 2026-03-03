#!/bin/sh
set -e

# =============================================
# Entrypoint para el contenedor NestJS
# =============================================

LOG_DIR="/root/logs"
LOG_FILE="$LOG_DIR/informe_nest.log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

echo "=== Iniciando NestJS App ===" >> "$LOG_FILE"
echo "Fecha: $(date)" >> "$LOG_FILE"
echo "DB_HOST: ${DB_HOST}" >> "$LOG_FILE"
echo "DB_PORT: ${DB_PORT}" >> "$LOG_FILE"
echo "DATABASE: ${DATABASE}" >> "$LOG_FILE"
echo "PORT: ${PORT}" >> "$LOG_FILE"

# =============================================
# Esperar a que PostgreSQL esté disponible
# =============================================
wait_for_postgres() {
    echo "Esperando a que PostgreSQL esté disponible en ${DB_HOST}:${DB_PORT}..." >> "$LOG_FILE"

    MAX_RETRIES=30
    RETRY_COUNT=0

    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        # Intentar conexión TCP al puerto de PostgreSQL
        if nc -z "${DB_HOST}" "${DB_PORT}" 2>/dev/null; then
            echo "PostgreSQL está disponible!" >> "$LOG_FILE"
            return 0
        fi

        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Intento $RETRY_COUNT/$MAX_RETRIES - PostgreSQL no disponible, reintentando en 2s..." >> "$LOG_FILE"
        sleep 2
    done

    echo "ERROR: No se pudo conectar a PostgreSQL después de $MAX_RETRIES intentos" >> "$LOG_FILE"
    exit 1
}

# Instalar netcat para el health check (no está en alpine por defecto)
apk add --no-cache netcat-openbsd > /dev/null 2>&1 || true

# Esperar a PostgreSQL
wait_for_postgres

# =============================================
# Arrancar la aplicación NestJS en modo producción
# =============================================
echo "Arrancando NestJS en modo producción..." >> "$LOG_FILE"
echo "Comando: node dist/main.js" >> "$LOG_FILE"

exec node dist/main.js
