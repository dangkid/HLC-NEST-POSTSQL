#!/bin/bash

LOG_DIR="/root/logs"
LOG_FILE="$LOG_DIR/informe_postgre.log"

PG_USER="pokemonuser"
PG_PASSWORD="pokemonpass123"
PG_DATABASE="pokemondb"
PG_PORT="5432"

PG_VERSION=$(ls /usr/lib/postgresql/ | sort -V | tail -1)
PG_BIN="/usr/lib/postgresql/$PG_VERSION/bin"
PGDATA="/var/lib/postgresql/data/pgdata"

log() {
    echo "$1"
    echo "$1" >> "$LOG_FILE"
}

load_entrypoint_seguridad() {
    log "Ejecutando entrypoint seguridad..."

    if [ -f /root/admin/ubseguridad/damgstart.sh ]; then
        bash /root/admin/ubseguridad/damgstart.sh || log "ADVERTENCIA: Entrypoint seguridad falló, continuando..."
        log "Entrypoint seguridad ejecutado"
    else
        log "ADVERTENCIA: No se encontró /root/admin/ubseguridad/damgstart.sh"
    fi
}

inicializar_cluster() {
    if [ ! -f "$PGDATA/PG_VERSION" ]; then
        log "Inicializando cluster PostgreSQL (v$PG_VERSION)..."
        mkdir -p "$PGDATA"
        chown -R postgres:postgres /var/lib/postgresql/data
        chmod 700 "$PGDATA"
        su - postgres -c "$PG_BIN/initdb -D $PGDATA" || { log "ERROR: Falló initdb"; return 1; }
        log "Cluster inicializado"
    else
        log "Cluster PostgreSQL ya existe, saltando inicialización"
    fi
}

configurar_acceso() {
    log "Configurando acceso remoto..."

    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PGDATA/postgresql.conf"
    sed -i "s/#port = 5432/port = $PG_PORT/" "$PGDATA/postgresql.conf"

    if ! grep -q "host all all 0.0.0.0/0 md5" "$PGDATA/pg_hba.conf"; then
        echo "host all all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
    fi

    log "Acceso remoto configurado"
}

crear_usuario_y_bd() {
    log "Arrancando PostgreSQL temporalmente para configuración..."

    su - postgres -c "$PG_BIN/pg_ctl -D $PGDATA start -w -l /var/lib/postgresql/logfile" || { log "ERROR: No se pudo arrancar PostgreSQL"; return 1; }

    # Escribir SQL en directorio de postgres para evitar problemas de permisos
    echo "CREATE USER $PG_USER WITH PASSWORD '$PG_PASSWORD';" > /var/lib/postgresql/init.sql
    echo "CREATE DATABASE $PG_DATABASE OWNER $PG_USER;" >> /var/lib/postgresql/init.sql
    echo "GRANT ALL PRIVILEGES ON DATABASE $PG_DATABASE TO $PG_USER;" >> /var/lib/postgresql/init.sql
    chown postgres:postgres /var/lib/postgresql/init.sql

    su - postgres -c "$PG_BIN/psql -f /var/lib/postgresql/init.sql" >> "$LOG_FILE" 2>&1 && log "Usuario '$PG_USER' y BD '$PG_DATABASE' configurados" || log "ADVERTENCIA: usuario/bd ya existían"

    su - postgres -c "$PG_BIN/pg_ctl -D $PGDATA stop -w"

    log "Configuración de usuario y BD completada"
}

arrancar_postgresql_foreground() {
    log "Arrancando PostgreSQL en primer plano..."
    exec su - postgres -c "$PG_BIN/postgres -D $PGDATA"
}

main() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"

    log "=== Iniciando capa PostgreSQL (v$PG_VERSION) ==="
    log "Fecha: $(date)"
    log "Usuario: $PG_USER | BD: $PG_DATABASE | Puerto: $PG_PORT"

    load_entrypoint_seguridad
    inicializar_cluster
    configurar_acceso
    crear_usuario_y_bd
    arrancar_postgresql_foreground

    log "=== Capa PostgreSQL configurada correctamente ==="
}

main
