#!/bin/bash

LOG_DIR="/root/logs"
LOG_FILE="$LOG_DIR/informe_web.log"

log() {
    echo "$1"
    echo "$1" >> "$LOG_FILE"
}

load_entrypoint_postgre(){
    log "Cargando entrypoint PostgreSQL..."
    
    if [ -f /root/admin/postgre/damgstart.sh ]; then
        bash /root/admin/postgre/damgstart.sh || log "ADVERTENCIA: Entrypoint PostgreSQL falló, continuando..."
        log "Entrypoint PostgreSQL ejecutado"
    else
        log "ADVERTENCIA: damgstart.sh de PostgreSQL no encontrado"
    fi
}

load_entrypoint_nginx(){
    log "Cargando entrypoint Nginx..."
    
    if [ -f /root/admin/sweb/nginx/damgstart.sh ]; then
        bash /root/admin/sweb/nginx/damgstart.sh || log "ADVERTENCIA: Entrypoint Nginx falló, continuando..."
        log "Entrypoint Nginx ejecutado"
    else
        log "ADVERTENCIA: damgstart.sh de Nginx no encontrado"
    fi
}

directorio_de_trabajo(){
    log "Cambiando directorio al proyecto NestJS..."

    if cd /root/admin/node/proyectos/nestpostgresql; then
        log "Directorio cambiado a: $(pwd)"
    else
        log "ERROR: No se pudo cambiar al directorio del proyecto NestJS"
        exit 1
    fi
}

construir_y_arrancar(){
    log "Instalando dependencias NestJS..."
    
    npm install
    
    if npm run build; then
        log "Proyecto NestJS construido"
    else
        log "ERROR: Falló npm run build"
        exit 1
    fi
    
    if [ -d public ]; then
        cp -r public/* /var/www/html/ 2>/dev/null || true
        log "Archivos estáticos copiados a /var/www/html"
    else
        log "ADVERTENCIA: Directorio public no encontrado"
    fi
    
    log "Arrancando NestJS en segundo plano..."
    HOST=0.0.0.0 npm run start:prod &
}

cargar_nginx(){
    log "Configurando Nginx..."
    
    nginx -t 2>&1 || log "ADVERTENCIA: nginx -t falló"
    log "Nginx arrancando en primer plano..."
    nginx -g 'daemon off;'
}

load_entrypoint_base(){
    log "Cargando entrypoint base (SSH, usuario, sudo)..."
    if [ -f /root/admin/base/damgstart.sh ]; then
        bash /root/admin/base/damgstart.sh || log "ADVERTENCIA: Entrypoint base falló, continuando..."
        log "Entrypoint base ejecutado"
    else
        log "ADVERTENCIA: damgstart.sh de base no encontrado"
    fi
}

main(){
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    log "=== Iniciando contenedor NestJS ==="
    log "Fecha: $(date)"
    load_entrypoint_base
    load_entrypoint_postgre
    load_entrypoint_nginx
    directorio_de_trabajo
    construir_y_arrancar
    cargar_nginx
}

main
