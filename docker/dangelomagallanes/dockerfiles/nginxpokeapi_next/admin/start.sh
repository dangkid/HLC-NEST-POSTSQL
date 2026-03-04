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
npm run build 2>&1 | tee -a /root/logs/next_final/next_final.log
echo "[$(date)] ✓ Next.js compilado exitosamente" >> /root/logs/next_final/next_final.log

# 2. Iniciar Next.js en background con nohup
echo "[$(date)] Iniciando servidor Next.js en puerto 3000 con nohup..." >> /root/logs/next_final/next_final.log
nohup npm start > /root/logs/next_final/nextjs.log 2>&1 &
NEXT_PID=$!
echo "[$(date)] Proceso Next.js iniciado con PID $NEXT_PID" >> /root/logs/next_final/next_final.log

# Esperar más tiempo para que Next.js esté completamente listo
echo "[$(date)] Esperando 15 segundos para que Next.js se inicie completamente..." >> /root/logs/next_final/next_final.log
sleep 15

# Verificar que Next.js está respondiendo
echo "[$(date)] Verificando conectividad a localhost:3000..." >> /root/logs/next_final/next_final.log
for i in {1..10}; do
    if wget -q -O - http://localhost:3000/ >/dev/null 2>&1; then
        echo "[$(date)] ✓ Next.js respondiendo correctamente en puerto 3000" >> /root/logs/next_final/next_final.log
        break
    fi
    echo "[$(date)] Intento $i/10 falló, reintentando..." >> /root/logs/next_final/next_final.log
    sleep 2
done

# 3. Configurar Nginx como proxy
echo "[$(date)] Configurando Nginx como proxy hacia localhost:3000" >> /root/logs/next_final/next_final.log
cp /root/admin/nginxpokeapi_next/nginx.conf /etc/nginx/sites-available/default

# Validar configuración
echo "[$(date)] Validando configuración de Nginx..." >> /root/logs/next_final/next_final.log
if ! nginx -t 2>&1 | tee -a /root/logs/next_final/next_final.log; then
    echo "[$(date)] ✗ ERROR: Configuración de Nginx inválida" >> /root/logs/next_final/next_final.log
    exit 1
fi

echo "[$(date)] ✓ Configuración de Nginx validada" >> /root/logs/next_final/next_final.log

# 4. Iniciar Nginx en foreground
echo "[$(date)] Iniciando Nginx en puerto 80 (daemon off)" >> /root/logs/next_final/next_final.log
echo "[$(date)] ===== Contenedor completamente operacional =====" >> /root/logs/next_final/next_final.log
cat /root/logs/next_final/next_final.log
nginx -g "daemon off;"
