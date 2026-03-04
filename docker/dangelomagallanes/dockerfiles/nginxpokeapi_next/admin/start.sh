#!/bin/bash

set -e

mkdir -p /root/logs/next_final
touch /root/logs/next_final/next_final.log

# 1. Ejecutar seguridad (no bloqueante)
if [ -f "/root/admin/ubseguridad/damgstart.sh" ]; then
    bash /root/admin/ubseguridad/damgstart.sh &
    echo "[$(date)] Entrypoint seguridad cargado" >> /root/logs/next_final/next_final.log
fi

# 2. Preparar aplicación Next.js
cd /root/admin/node_next/next-pokeapi
echo "[$(date)] Iniciando compilación de Next.js en $(pwd)" >> /root/logs/next_final/next_final.log

# Instalar dependencias
npm install 2>&1 | tail -5 >> /root/logs/next_final/next_final.log

# Compilar Next.js
npm run build 2>&1 | tail -10 >> /root/logs/next_final/next_final.log
echo "[$(date)] Next.js compilado exitosamente" >> /root/logs/next_final/next_final.log

# 3. Iniciar Next.js en segundo plano en puerto 3000
echo "[$(date)] Iniciando servidor Next.js en puerto 3000" >> /root/logs/next_final/next_final.log
npm start &
NEXT_PID=$!
sleep 5
echo "[$(date)] Proceso Next.js iniciado con PID $NEXT_PID" >> /root/logs/next_final/next_final.log

# 4. Configurar y iniciar Nginx como proxy
cp /root/admin/nginxpokeapi_next/nginx.conf /etc/nginx/sites-available/default
echo "[$(date)] Configuración de Nginx aplicada" >> /root/logs/next_final/next_final.log

# Iniciar Nginx
echo "[$(date)] Iniciando Nginx como proxy en puerto 80 hacia localhost:3000" >> /root/logs/next_final/next_final.log
nginx -g "daemon off;"
