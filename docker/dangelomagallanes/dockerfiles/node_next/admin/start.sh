#!/bin/bash

# Script de inicialización para capa node_next
# Este script prepara la aplicación Node.js/Next.js
# El entrypoint final se controla desde nginxpokeapi_next

mkdir -p /root/logs/node_next
touch /root/logs/node_next/node_next.log

echo "[node_next] Preparando aplicación Next.js..." >> /root/logs/node_next/node_next.log

# Navegar a la aplicación
cd /root/admin/node_next/next-pokeapi

# Instalar dependencias
echo "[node_next] Instalando dependencias npm..." >> /root/logs/node_next/node_next.log
npm install >> /root/logs/node_next/node_next.log 2>&1

echo "[node_next] ✓ Aplicación preparada" >> /root/logs/node_next/node_next.log
echo "[node_next] Control pasado al siguiente entrypoint"
