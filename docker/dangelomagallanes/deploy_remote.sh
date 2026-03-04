#!/bin/bash

#############################################################
# SCRIPT DE DESPLIEGUE REMOTO EN VPS CON HELM
# 
# Este script ejecuta el despliegue directamente en la VPS
# mediante SSH.
#
# Uso: ./deploy_remote.sh [VPS_USER@VPS_IP]
# Ejemplo: ./deploy_remote.sh dangelo@37.60.238.102
#############################################################

set -e

VPS_HOST="${1:-}"
SSH_PORT="23456"
REMOTE_PROJECT_PATH="/home/dangelo/HLC-NEST-POSTSQL"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ -z "$VPS_HOST" ]; then
    log_error "Uso: ./deploy_remote.sh [VPS_USER@VPS_IP]"
    log_error "Ejemplo: ./deploy_remote.sh dangelo@37.60.238.102"
    exit 1
fi

echo ""
echo "=========================================="
echo " DESPLIEGUE REMOTO EN VPS"
echo " VPS: $VPS_HOST"
echo "=========================================="
echo ""

read -p "¿Desplegar en VPS $VPS_HOST? (s/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    log "Despliegue cancelado"
    exit 0
fi

log "Conectando a VPS..."
ssh -p $SSH_PORT $VPS_HOST << 'EOF'
set -e

DOCKER_USER="dangekid"
PROJECT_PATH="/home/dangelo/HLC-NEST-POSTSQL/docker/dangelomagallanes"
NAMESPACE="proyecto-nest"

echo ""
echo "=========================================="
echo " DESPLIEGUE AUTOMÁTICO EN VPS"
echo " Usuario: $DOCKER_USER"
echo " Namespace: $NAMESPACE"
echo "=========================================="
echo ""

# Fase 1: Pull del código más reciente
echo "[1/4] Actualizando código del repositorio..."
cd $PROJECT_PATH
git pull origin main
echo "✓ Código actualizado"

echo ""
echo "[2/4] Desplegando con Helm..."

# Crear namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true

# Desplegar NestJS
echo "  - Desplegando NestJS API..."
helm upgrade --install nest-api ./proyecto/personal/nest-con-helm \
    --namespace $NAMESPACE \
    --values ./proyecto/personal/nest-con-helm/values.yaml \
    --wait --timeout 5m

# Desplegar Next.js
echo "  - Desplegando Next.js Frontend..."
helm upgrade --install next-frontend ./proyecto/personal/pokeapi-next-helm \
    --namespace $NAMESPACE \
    --values ./proyecto/personal/pokeapi-next-helm/values.yaml \
    --wait --timeout 5m

echo "✓ Despliegue con Helm completado"

echo ""
echo "[3/4] Esperando a que los servicios estén listos..."
sleep 15

echo ""
echo "[4/4] Verificando estado..."
echo ""
echo "Pods en namespace $NAMESPACE:"
kubectl get pods -n $NAMESPACE -o wide

echo ""
echo "Servicios:"
kubectl get svc -n $NAMESPACE

echo ""
echo "=========================================="
echo "✓ DESPLIEGUE COMPLETADO EN VPS"
echo "=========================================="
echo ""
echo "Acceso:"
echo "  API:      http://37.60.238.102:30010/pokemon"
echo "  Frontend: http://37.60.238.102:30087/"
echo ""

EOF

log_success "Despliegue remoto completado"
