#!/bin/bash

#############################################################
# FIX LOCAL: NGINX PROXY MANAGER - FORWARD HOST
#
# Ejecutar DIRECTAMENTE en la VPS (no requiere SSH).
# Cambia forward_host de 127.0.0.1 → 172.17.0.1 en NPM
# para que api.dangelomagallanes.me y pokemon.dangelomagallanes.me
# alcancen los NodePorts de Kubernetes en el host.
#
# Uso (desde la VPS):
#   bash fix_npm_hosts_local.sh
#############################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()         { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

OLD_HOST="127.0.0.1"
NEW_HOST="172.17.0.1"
DB_PATH="/data/database.sqlite"

echo ""
echo "=========================================="
echo " FIX NPM FORWARD HOSTS (LOCAL)"
echo "=========================================="
echo ""

# ── 1. Localizar el contenedor de NPM ─────────────────────
log "Buscando contenedor de Nginx Proxy Manager..."

NPM_CONTAINER=$(docker ps --format '{{.Names}}' | grep -iE 'nginx.proxy.manager|npm|nginxproxymanager' | head -1)

if [ -z "$NPM_CONTAINER" ]; then
    NPM_CONTAINER=$(docker ps --format '{{.Names}}\t{{.Image}}' | grep -i 'jc21/nginx-proxy-manager' | awk '{print $1}' | head -1)
fi

if [ -z "$NPM_CONTAINER" ]; then
    log_error "No se encontró el contenedor de NPM."
    log_error "Contenedores corriendo:"
    docker ps --format "  {{.Names}} ({{.Image}})"
    exit 1
fi

log_success "Contenedor NPM: $NPM_CONTAINER"

# ── 2. Verificar sqlite3 ───────────────────────────────────
if ! docker exec "$NPM_CONTAINER" which sqlite3 > /dev/null 2>&1; then
    log_warning "sqlite3 no disponible en el contenedor. Instalando..."
    docker exec "$NPM_CONTAINER" sh -c "apt-get update -qq && apt-get install -y -qq sqlite3" 2>/dev/null || \
    docker exec "$NPM_CONTAINER" sh -c "apk add --no-cache sqlite" || {
        log_error "No se pudo instalar sqlite3."
        exit 1
    }
fi

# ── 3. Mostrar estado actual ───────────────────────────────
log "Estado actual en NPM:"
docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
    "SELECT id, domain_names, forward_host, forward_port FROM proxy_host WHERE is_deleted = 0;" \
    2>/dev/null | column -t -s '|' || true
echo ""

# ── 4. Contar registros a cambiar ─────────────────────────
ROWS=$(docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
    "SELECT COUNT(*) FROM proxy_host WHERE forward_host = '$OLD_HOST' AND is_deleted = 0;" 2>/dev/null)

if [ "$ROWS" -eq 0 ]; then
    log_warning "No hay registros con forward_host='$OLD_HOST'. Verificando todos los hosts:"
    docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
        "SELECT id, domain_names, forward_host, forward_port FROM proxy_host WHERE is_deleted = 0;"
    exit 0
fi

# ── 5. Aplicar fix ────────────────────────────────────────
log "Actualizando $ROWS registro(s): $OLD_HOST → $NEW_HOST..."

docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
    "UPDATE proxy_host SET forward_host = '$NEW_HOST' WHERE forward_host = '$OLD_HOST' AND is_deleted = 0;"

log_success "Registros actualizados."

# ── 6. Verificar resultado ─────────────────────────────────
log "Estado después del fix:"
docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
    "SELECT id, domain_names, forward_host, forward_port FROM proxy_host WHERE is_deleted = 0;" \
    2>/dev/null | column -t -s '|' || true
echo ""

# ── 7. Reiniciar NPM ──────────────────────────────────────
log "Reiniciando NPM para aplicar cambios..."
docker restart "$NPM_CONTAINER"
log_success "Esperando que NPM levante..."
sleep 8

if docker ps --format '{{.Names}}' | grep -q "^${NPM_CONTAINER}$"; then
    log_success "NPM corriendo correctamente."
else
    log_error "NPM no levantó después del reinicio."
    exit 1
fi

echo ""
echo "=========================================="
echo " FIX APLICADO"
echo "=========================================="
echo "  api.dangelomagallanes.me     → 172.17.0.1:30010"
echo "  pokemon.dangelomagallanes.me → 172.17.0.1:30087"
echo ""
echo "  Verificar:"
echo "  curl -I https://api.dangelomagallanes.me/pokemon"
echo "  curl -I https://pokemon.dangelomagallanes.me"
echo ""
