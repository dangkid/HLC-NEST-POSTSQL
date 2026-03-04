#!/bin/bash

#############################################################
# SCRIPT DE DESPLIEGUE CON HELM - D'Angelo Magallanes
# 
# Este script automatiza todo el proceso:
# 1. Construir todas las imágenes Docker en orden
# 2. Empujar a Docker Hub
# 3. Desplegar/actualizar en Kubernetes con Helm
#
# Uso: ./deploy_helm.sh [namespace] [vps-user@vps-ip]
# Ejemplo: ./deploy_helm.sh proyecto-nest dangelo@37.60.238.102
#############################################################

set -e

# Variables por defecto
NAMESPACE="${1:-proyecto-nest}"
VPS_HOST="${2:-}"
SSH_PORT="23456"
DOCKER_USER="dangekid"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKERFILES_DIR="$BASE_DIR/dockerfiles"
HELM_CHARTS_DIR="$BASE_DIR/proyecto/personal"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de logging
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Mostrar banner
banner() {
    echo ""
    echo "=========================================="
    echo " DESPLIEGUE AUTOMATIZADO CON HELM"
    echo " Proyecto: Pokemon API (NestJS + Next.js)"
    echo " Usuario Docker: $DOCKER_USER"
    echo " Namespace K8s: $NAMESPACE"
    echo "=========================================="
    echo ""
}

# Verificar prerrequisitos
check_prerequisites() {
    log "Verificando prerrequisitos..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado"
        exit 1
    fi
    log_success "Docker encontrado"
    
    # Verificar Helm
    if ! command -v helm &> /dev/null; then
        log_error "Helm no está instalado"
        exit 1
    fi
    log_success "Helm encontrado"
    
    # Verificar kubectl (si hay host remoto)
    if [ -n "$VPS_HOST" ]; then
        if ! command -v ssh &> /dev/null; then
            log_error "SSH no está disponible"
            exit 1
        fi
        log_success "SSH encontrado"
    fi
    
    echo ""
}

# Construir todas las imágenes Docker
build_images() {
    log "=========================================="
    log "FASE 1: Construyendo imágenes Docker"
    log "=========================================="
    
    # 1. ubbase
    log "Construyendo $DOCKER_USER/ubbase..."
    docker build -t $DOCKER_USER/ubbase -f $DOCKERFILES_DIR/ubbase/damgubbase $BASE_DIR
    log_success "$DOCKER_USER/ubbase"
    
    # 2. ubseguridad
    log "Construyendo $DOCKER_USER/ubseguridad..."
    docker build -t $DOCKER_USER/ubseguridad -f $DOCKERFILES_DIR/ubseguridad/damgubseguridad $BASE_DIR
    log_success "$DOCKER_USER/ubseguridad"
    
    # 3. nginx1
    log "Construyendo $DOCKER_USER/nginx1..."
    docker build -t $DOCKER_USER/nginx1 -f $DOCKERFILES_DIR/sweb/nginx/damgnginx $BASE_DIR
    log_success "$DOCKER_USER/nginx1"
    
    # 4. postgre
    log "Construyendo $DOCKER_USER/postgre..."
    docker build -t $DOCKER_USER/postgre -f $DOCKERFILES_DIR/postgre/damgpostgre $BASE_DIR
    log_success "$DOCKER_USER/postgre"
    
    # 5. pokeapi (NestJS)
    log "Construyendo $DOCKER_USER/pokeapi..."
    docker build -t $DOCKER_USER/pokeapi -f $DOCKERFILES_DIR/nest/damgpokeapi $BASE_DIR
    log_success "$DOCKER_USER/pokeapi"
    
    # 6. pokeapinext (Next.js)
    log "Construyendo $DOCKER_USER/pokeapinext..."
    docker build -t $DOCKER_USER/pokeapinext -f $DOCKERFILES_DIR/node_next/dockerfiles $BASE_DIR
    log_success "$DOCKER_USER/pokeapinext"
    
    # 7. nginxpokeapi (FINAL NestJS)
    log "Construyendo $DOCKER_USER/nginxpokeapi..."
    docker build -t $DOCKER_USER/nginxpokeapi -f $DOCKERFILES_DIR/nginxpokeapi/damgnginxpokeapi $BASE_DIR
    log_success "$DOCKER_USER/nginxpokeapi"
    
    # 8. pokeapi_next_finalizado (FINAL Next.js)
    log "Construyendo $DOCKER_USER/pokeapi_next_finalizado..."
    docker build -t $DOCKER_USER/pokeapi_next_finalizado -f $DOCKERFILES_DIR/nginxpokeapi_next/dockerfiles $BASE_DIR
    log_success "$DOCKER_USER/pokeapi_next_finalizado"
    
    echo ""
    log_success "Todas las imágenes construidas"
    echo ""
}

# Empujar imágenes a Docker Hub
push_images() {
    log "=========================================="
    log "FASE 2: Empujando imágenes a Docker Hub"
    log "=========================================="
    
    # Verificar si está logueado
    if ! docker info | grep -q "Username"; then
        log_warning "No estás logueado en Docker Hub"
        log "Ejecuta: docker login"
        read -p "¿Continuar de todas formas? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 1
        fi
    fi
    
    # Empujar imágenes
    for image in ubbase ubseguridad nginx1 postgre pokeapi pokeapinext nginxpokeapi pokeapi_next_finalizado; do
        log "Empujando $DOCKER_USER/$image..."
        docker push $DOCKER_USER/$image
        log_success "$DOCKER_USER/$image empujada"
    done
    
    echo ""
    log_success "Todas las imágenes empujadas a Docker Hub"
    echo ""
}

# Desplegar con Helm en Kubernetes
deploy_helm() {
    log "=========================================="
    log "FASE 3: Desplegando con Helm"
    log "=========================================="
    
    # Crear namespace si no existe
    log "Creando namespace $NAMESPACE..."
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    log_success "Namespace $NAMESPACE listo"
    
    # Desplegar NestJS API
    log "Desplegando NestJS API con Helm..."
    helm upgrade --install nest-api $HELM_CHARTS_DIR/nest-con-helm \
        --namespace $NAMESPACE \
        --values $HELM_CHARTS_DIR/nest-con-helm/values.yaml
    log_success "NestJS API desplegada"
    
    # Desplegar Next.js Frontend
    log "Desplegando Next.js Frontend con Helm..."
    helm upgrade --install next-frontend $HELM_CHARTS_DIR/pokeapi-next-helm \
        --namespace $NAMESPACE \
        --values $HELM_CHARTS_DIR/pokeapi-next-helm/values.yaml
    log_success "Next.js Frontend desplegada"
    
    echo ""
    log_success "Despliegue con Helm completado"
    echo ""
}

# Verificar estado del despliegue
verify_deployment() {
    log "=========================================="
    log "FASE 4: Verificando despliegue"
    log "=========================================="
    
    log "Esperando 10 segundos para que los pods se inicien..."
    sleep 10
    
    log "Estado de los pods:"
    kubectl get pods -n $NAMESPACE -o wide
    
    echo ""
    log "Servicios desplegados:"
    kubectl get svc -n $NAMESPACE
    
    echo ""
}

# Si hay host remoto, mostrar cómo acceder
show_access_info() {
    if [ -n "$VPS_HOST" ]; then
        log "=========================================="
        log "INFORMACIÓN DE ACCESO"
        log "=========================================="
        log "VPS: $VPS_HOST"
        log "Namespace: $NAMESPACE"
        echo ""
        log "Para ver los pods en la VPS:"
        log "  ssh -p $SSH_PORT $VPS_HOST \"kubectl get pods -n $NAMESPACE\""
        echo ""
        log "Para ver los logs de NestJS:"
        log "  ssh -p $SSH_PORT $VPS_HOST \"kubectl logs -n $NAMESPACE -l app=webnest --tail=100\""
        echo ""
        log "Para acceder a la API:"
        log "  http://<VPS_IP>:30010/pokemon"
        echo ""
        log "Para acceder al Frontend:"
        log "  http://<VPS_IP>:30087/"
        echo ""
    fi
}

# Main
main() {
    banner
    
    log "Configuración:"
    log "  Namespace: $NAMESPACE"
    log "  Docker User: $DOCKER_USER"
    log "  Base Dir: $BASE_DIR"
    if [ -n "$VPS_HOST" ]; then
        log "  VPS Host: $VPS_HOST"
    fi
    echo ""
    
    read -p "¿Continuar con el despliegue? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        log_warning "Despliegue cancelado"
        exit 0
    fi
    
    check_prerequisites
    build_images
    push_images
    deploy_helm
    verify_deployment
    show_access_info
    
    echo ""
    log_success "=========================================="
    log_success "¡DESPLIEGUE COMPLETADO CON ÉXITO!"
    log_success "=========================================="
    echo ""
}

# Ejecutar main
main
