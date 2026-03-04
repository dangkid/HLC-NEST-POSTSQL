#!/bin/bash

#############################################################
# SCRIPT DE VERIFICACIÓN POST-DESPLIEGUE
# 
# Verifica que todos los componentes estén funcionando
# correctamente después del despliegue con Helm
#############################################################

set -e

NAMESPACE="${1:-proyecto-nest}"
VPS_HOST="${2:-}"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

test_count=0
pass_count=0

test_result() {
    test_count=$((test_count + 1))
    if [ $1 -eq 0 ]; then
        pass_count=$((pass_count + 1))
        log_success "$2"
    else
        log_error "$2"
    fi
}

echo ""
echo "=========================================="
echo " VERIFICACIÓN POST-DESPLIEGUE"
echo " Namespace: $NAMESPACE"
echo "=========================================="
echo ""

# Si se proporciona VPS host, conectar remotamente
if [ -n "$VPS_HOST" ]; then
    log "Conectando a VPS para verificación remota..."
    ssh -p 23456 $VPS_HOST << EOF
set -e
NAMESPACE="$NAMESPACE"

echo "1. Estado de Pods"
echo "================"
kubectl get pods -n \$NAMESPACE -o wide

if [ \$(kubectl get pods -n \$NAMESPACE | grep -c "1/1 Running") -ge 2 ]; then
    echo "✓ Pods están en estado Ready"
else
    echo "✗ Algunos pods no están Ready aún"
fi

echo ""
echo "2. Servicios Disponibles"
echo "======================="
kubectl get svc -n \$NAMESPACE

echo ""
echo "3. Helm Releases"
echo "================"
helm list -n \$NAMESPACE

echo ""
echo "4. Información de Acceso"
echo "======================"
API_IP=\$(kubectl get svc -n \$NAMESPACE nest-api -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDIENTE")
API_NODEPORT=\$(kubectl get svc -n \$NAMESPACE nest-api -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
FRONTEND_NODEPORT=\$(kubectl get svc -n \$NAMESPACE next-frontend -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)

echo "API NestJS:"
echo "  NodePort: \$API_NODEPORT"
echo "  URL: http://37.60.238.102:\$API_NODEPORT/pokemon"
echo ""
echo "Frontend Next.js:"
echo "  NodePort: \$FRONTEND_NODEPORT"  
echo "  URL: http://37.60.238.102:\$FRONTEND_NODEPORT/"
EOF
else
    # Verificación local
    log "Ejecutando verificación local..."
    
    echo ""
    echo "1. Estado de Pods"
    echo "================"
    kubectl get pods -n $NAMESPACE -o wide
    
    ready_pods=$(kubectl get pods -n $NAMESPACE 2>/dev/null | grep -c "1/1" || true)
    test_result $([ $ready_pods -ge 1 ] && echo 0 || echo 1) "Pods en estado Ready ($ready_pods/2)"
    
    echo ""
    echo "2. Servicios Disponibles"
    echo "======================="
    kubectl get svc -n $NAMESPACE
    
    echo ""
    echo "3. Helm Releases"
    echo "================"
    helm list -n $NAMESPACE 2>/dev/null || log_warning "Helm no disponible localmente"
    
    echo ""
    echo "4. Descripción de Deployments"
    echo "============================"
    kubectl describe deployment -n $NAMESPACE 2>/dev/null | grep -A5 "Replicas:"
    
    echo ""
    echo "5. Eventos Recientes"
    echo "==================="
    kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
fi

echo ""
echo "=========================================="
echo "RESUMEN DE VERIFICACIÓN"
echo "=========================================="
echo "Tests Pasados: $pass_count/$test_count"
echo ""
echo "Próximos Pasos:"
echo "1. Esperar 2-3 minutos para que los pods estén completamente listos"
echo "2. Probar API: curl http://37.60.238.102:30010/pokemon"
echo "3. Probar Frontend: Abrir http://37.60.238.102:30087/ en navegador"
echo ""
