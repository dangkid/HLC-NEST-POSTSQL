#!/bin/bash

#############################################################
# FIX: NGINX PROXY MANAGER - FORWARD HOST
#
# Problema: NPM corre en Docker y usa 127.0.0.1 como forward
# hostname, que dentro del contenedor apunta al propio NPM,
# no al host VPS. Los NodePorts de Kubernetes (30010, 30087)
# están en el host, no en el contenedor.
#
# Solución: Cambiar 127.0.0.1 → 172.17.0.1 (Docker bridge
# gateway) en los proxy hosts de NPM para que alcance el host.
#
# Uso: ./fix_npm_hosts.sh [VPS_USER@VPS_IP]
# Ejemplo: ./fix_npm_hosts.sh dangelo@37.60.238.102
#############################################################

set -e

VPS_HOST="${1:-}"
SSH_PORT="23456"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()         { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

if [ -z "$VPS_HOST" ]; then
    log_error "Uso: ./fix_npm_hosts.sh [VPS_USER@VPS_IP]"
    log_error "Ejemplo: ./fix_npm_hosts.sh dangelo@37.60.238.102"
    exit 1
fi

echo ""
echo "=========================================="
echo " FIX NPM FORWARD HOSTS"
echo " VPS: $VPS_HOST"
echo "=========================================="
echo ""
echo "  Dominio              Forward actual    →  Correcto"
echo "  api.dangelomagallanes.me    127.0.0.1:30010  →  172.17.0.1:30010"
echo "  pokemon.dangelomagallanes.me 127.0.0.1:30087 →  172.17.0.1:30087"
echo ""

read -p "¿Aplicar fix en $VPS_HOST? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log "Cancelado"
    exit 0
fi

log "Conectando a VPS y aplicando fix..."

ssh -p "$SSH_PORT" "$VPS_HOST" 'bash -s' << 'ENDSSH'
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

# ── 1. Localizar el contenedor de NPM ─────────────────────
log "Buscando contenedor de Nginx Proxy Manager..."

NPM_CONTAINER=$(docker ps --format '{{.Names}}' | grep -iE 'nginx.proxy.manager|npm|nginxproxymanager' | head -1)

if [ -z "$NPM_CONTAINER" ]; then
    # Fallback: buscar por imagen
    NPM_CONTAINER=$(docker ps --format '{{.Names}}\t{{.Image}}' | grep -i 'jc21/nginx-proxy-manager' | awk '{print $1}' | head -1)
fi

if [ -z "$NPM_CONTAINER" ]; then
    log_error "No se encontró el contenedor de NPM."
    log_error "Contenedores corriendo:"
    docker ps --format "  {{.Names}} ({{.Image}})"
    exit 1
fi

log_success "Contenedor NPM: $NPM_CONTAINER"

# ── 2. Verificar que sqlite3 está disponible en el contenedor ──
if ! docker exec "$NPM_CONTAINER" which sqlite3 > /dev/null 2>&1; then
    log_warning "sqlite3 no está disponible en el contenedor. Instalando..."
    docker exec "$NPM_CONTAINER" sh -c "apt-get update -qq && apt-get install -y -qq sqlite3" || \
    docker exec "$NPM_CONTAINER" sh -c "apk add --no-cache sqlite" || {
        log_error "No se pudo instalar sqlite3 en el contenedor."
        exit 1
    }
fi

# ── 3. Mostrar estado actual ───────────────────────────────
log "Estado actual de proxy_host en NPM:"
docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
    "SELECT id, domain_names, forward_host, forward_port FROM proxy_host WHERE is_deleted = 0;" \
    2>/dev/null | column -t -s '|' || true

echo ""

# ── 4. Aplicar el fix (sólo dominios que usan 127.0.0.1) ──
log "Actualizando forward_host de $OLD_HOST → $NEW_HOST..."

ROWS=$(docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
    "SELECT COUNT(*) FROM proxy_host WHERE forward_host = '$OLD_HOST' AND is_deleted = 0;" \
    2>/dev/null)

if [ "$ROWS" -eq 0 ]; then
    log_warning "No hay registros con forward_host='$OLD_HOST'. ¿Ya está corregido?"
    docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
        "SELECT id, domain_names, forward_host, forward_port FROM proxy_host WHERE is_deleted = 0;"
    exit 0
fi

docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
    "UPDATE proxy_host SET forward_host = '$NEW_HOST' WHERE forward_host = '$OLD_HOST' AND is_deleted = 0;"

log_success "$ROWS registro(s) actualizados."

# ── 5. Verificar resultado ─────────────────────────────────
log "Estado después del fix:"
docker exec "$NPM_CONTAINER" sqlite3 "$DB_PATH" \
    "SELECT id, domain_names, forward_host, forward_port FROM proxy_host WHERE is_deleted = 0;" \
    2>/dev/null | column -t -s '|' || true

# ── 6. Recargar NPM para que aplique los cambios ──────────
log "Recargando Nginx Proxy Manager..."

# NPM expone un endpoint interno para regenerar configs de Nginx
docker exec "$NPM_CONTAINER" sh -c "nginx -s reload 2>/dev/null || true"

# Reiniciar el servicio interno de NPM para leer la DB actualizada
docker restart "$NPM_CONTAINER"

log_success "NPM reiniciado. Esperando que levante..."
sleep 8

# Verificar que el contenedor sigue corriendo
if docker ps --format '{{.Names}}' | grep -q "^${NPM_CONTAINER}$"; then
    log_success "NPM está corriendo correctamente."
else
    log_error "El contenedor NPM no está corriendo después del reinicio."
    exit 1
fi

echo ""
echo "=========================================="
echo " FIX APLICADO CORRECTAMENTE"
echo "=========================================="
echo ""
echo "  api.dangelomagallanes.me    → 172.17.0.1:30010"
echo "  pokemon.dangelomagallanes.me → 172.17.0.1:30087"
echo ""
echo "  Prueba los dominios:"
echo "  curl -I https://api.dangelomagallanes.me/pokemon"
echo "  curl -I https://pokemon.dangelomagallanes.me"
echo ""
ENDSSH

log_success "Fix completado desde el cliente local."
