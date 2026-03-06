#!/bin/bash

set -e

LOG="/root/logs/next_final/next_final.log"
mkdir -p /root/logs/next_final
touch "$LOG"

log() {
    echo "[$(date)] $1" | tee -a "$LOG"
}

log "===== Iniciando contenedor Next.js (static export) + Nginx ====="

# 1. Preparar y compilar Next.js (static export → genera directorio 'out/')
log "Preparando Next.js en /root/admin/node_next/next-pokeapi"
cd /root/admin/node_next/next-pokeapi

log "Instalando dependencias..."
npm install >> "$LOG" 2>&1

log "Compilando Next.js (static export)..."
npm run build 2>&1 | tee -a "$LOG"

# 2. Copiar archivos estáticos generados a /var/www/html
if [ -d "out" ]; then
    log "✓ Directorio 'out/' encontrado, copiando a /var/www/html/"
    rm -rf /var/www/html/*
    cp -r out/* /var/www/html/
    chown -R www-data:www-data /var/www/html
    log "✓ Archivos estáticos copiados correctamente"
else
    log "✗ ERROR: Directorio 'out/' no encontrado. Verificar next.config.js tiene output: 'export'"
    exit 1
fi

# 3. Configurar Nginx para servir archivos estáticos
log "Configurando Nginx para servir archivos estáticos"
cp /root/admin/nginxpokeapi_next/nginx.conf /etc/nginx/sites-available/default

log "Validando configuración de Nginx..."
if ! nginx -t 2>&1 | tee -a "$LOG"; then
    log "✗ ERROR: Configuración de Nginx inválida"
    exit 1
fi

log "✓ Configuración de Nginx validada"

# 4. Iniciar Nginx en foreground
log "Iniciando Nginx en puerto 80 (daemon off)"
log "===== Contenedor completamente operacional ====="
nginx -g "daemon off;"
