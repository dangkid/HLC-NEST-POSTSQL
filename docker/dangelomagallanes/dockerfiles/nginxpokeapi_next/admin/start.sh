#!/bin/bash

set -e

mkdir -p /root/logs/next_final
touch /root/logs/next_final/next_final.log

echo "[$(date)] ===== Iniciando contenedor Next.js + Nginx =====" >> /root/logs/next_final/next_final.log

# 1. Preparar aplicación Next.js
echo "[$(date)] Preparando Next.js en /root/admin/node_next/next-pokeapi" >> /root/logs/next_final/next_final.log
cd /root/admin/node_next/next-pokeapi

# Instalar dependencias
echo "[$(date)] Instalando dependencias..." >> /root/logs/next_final/next_final.log
npm install >> /root/logs/next_final/next_final.log 2>&1

# Compilar Next.js
echo "[$(date)] Compilando Next.js..." >> /root/logs/next_final/next_final.log
npm run build >> /root/logs/next_final/next_final.log 2>&1
echo "[$(date)] ✓ Next.js compilado exitosamente" >> /root/logs/next_final/next_final.log

# 2. Iniciar Next.js en background en puerto 3000
echo "[$(date)] Iniciando servidor Next.js en puerto 3000..." >> /root/logs/next_final/next_final.log
npm start > /root/logs/next_final/nextjs.log 2>&1 &
NEXT_PID=$!
echo "[$(date)] Proceso Next.js iniciado con PID $NEXT_PID" >> /root/logs/next_final/next_final.log

# Esperar a que Next.js esté listo
sleep 10
if ps -p $NEXT_PID > /dev/null; then
    echo "[$(date)] ✓ Next.js está corriendo" >> /root/logs/next_final/next_final.log
else
    echo "[$(date)] ✗ ERROR: Next.js falló al iniciar" >> /root/logs/next_final/next_final.log
    cat /root/logs/next_final/nextjs.log
    exit 1
fi

# 3. Configurar Nginx como proxy
echo "[$(date)] Configurando Nginx como proxy hacia localhost:3000" >> /root/logs/next_final/next_final.log
cp /root/admin/nginxpokeapi_next/nginx.conf /etc/nginx/sites-available/default

# Validar configuración
nginx -t >> /root/logs/next_final/next_final.log 2>&1 || {
    echo "[$(date)] ✗ ERROR: Configuración de Nginx inválida" >> /root/logs/next_final/next_final.log
    exit 1
}

echo "[$(date)] ✓ Configuración de Nginx validada" >> /root/logs/next_final/next_final.log

# 4. Iniciar Nginx en foreground
echo "[$(date)] Iniciando Nginx en puerto 80 (daemon off)" >> /root/logs/next_final/next_final.log
echo "[$(date)] ===== Contenedor completamente operacional =====" >> /root/logs/next_final/next_final.log
nginx -g "daemon off;"
