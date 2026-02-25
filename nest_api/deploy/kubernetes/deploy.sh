#!/bin/bash

# Deploy Pokemon API to Kubernetes
# Este script aplica todos los manifiestos de Kubernetes en orden

set -e

NAMESPACE="proyecto-nest"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo "╔════════════════════════════════════════════╗"
echo "║  Pokemon API - Kubernetes Deployment       ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# Verificar que kubectl está disponible
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl no está instalado"
    exit 1
fi

# Verificar conexión al cluster
echo "✓ Verificando conexión al cluster Kubernetes..."
kubectl cluster-info > /dev/null 2>&1 || {
    echo "❌ No hay conexión al cluster Kubernetes"
    exit 1
}

# Cambiar al directorio del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo ""
echo "📦 Aplicando manifiestos en orden..."
echo ""

# Aplicar en orden
for file in 01-namespace.yml 02-secret.yml 03-configmap.yml 04-pvc.yml \
            05-deploy-postgres.yml 06-service-postgres.yml \
            07-deploy-api.yml 08-service-api.yml 09-ingress.yml; do
    
    if [ -f "$file" ]; then
        echo "  → Aplicando $file..."
        kubectl apply -f "$file"
    else
        echo "  ⚠️  Archivo no encontrado: $file"
    fi
done

echo ""
echo "✓ Manifiestos aplicados exitosamente"
echo ""
echo "📋 Status de los pods:"
kubectl -n $NAMESPACE get pods
echo ""
echo "🔗 Accediendo a la API:"
echo "   Host: api.dangelomagallanes.me"
echo "   Puerto: 443 (HTTPS)"
echo ""
echo "💾 Base de datos:"
echo "   Host: postgres-pokemon-service"
echo "   Puerto: 5432"
echo ""
