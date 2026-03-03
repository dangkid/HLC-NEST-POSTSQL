#!/bin/bash

load_entrypoint_seguridad() {
    echo "Ejecutando entrypoint seguridad..." >> /root/logs/informe_nest.log
    
    if [ -f /root/admin/ubseguridad/damgstart.sh ]; then
        bash /root/admin/ubseguridad/damgstart.sh
        echo "Entrypoint seguridad ejecutado" >> /root/logs/informe_nest.log
    else
        echo "ADVERTENCIA: No se encontró /root/admin/ubseguridad/damgstart.sh" >> /root/logs/informe_nest.log
    fi
}

load_entrypoint_nginx(){
    echo "Cargando entrypoint Nginx..." >> /root/logs/informe_nest.log
    
    if [ -f /root/admin/sweb/nginx/start.sh ]; then
        bash /root/admin/sweb/nginx/start.sh
        echo "Entrypoint Nginx ejecutado" >> /root/logs/informe_nest.log
    else
        echo "ADVERTENCIA: start.sh de Nginx no encontrado" >> /root/logs/informe_nest.log
    fi
}

workdir(){
    echo "Cambiando directorio al proyecto NestJS..." >> /root/logs/informe_nest.log
    
    if [ -d /root/admin/node/proyectos/nestpostgresql ]; then
        cd /root/admin/node/proyectos/nestpostgresql
        echo "Directorio cambiado a: $(pwd)" >> /root/logs/informe_nest.log
    else
        echo "ERROR: Directorio /root/admin/node/proyectos/nestpostgresql no existe" >> /root/logs/informe_nest.log
        exit 1
    fi
}

dependencias-y-servicio(){
    echo "Instalando dependencias NestJS..." >> /root/logs/informe_nest.log
    
    if [ -f package.json ]; then
        npm install -g npm@11.7.0
        npm install && echo "Dependencias instaladas" >> /root/logs/informe_nest.log
        
        echo "Compilando proyecto NestJS..." >> /root/logs/informe_nest.log
        npm run build && echo "Proyecto compilado exitosamente" >> /root/logs/informe_nest.log
        
        echo "Arrancando NestJS en modo producción..." >> /root/logs/informe_nest.log
        HOST=0.0.0.0 npm run start:prod &
    else
        echo "ERROR: package.json no encontrado" >> /root/logs/informe_nest.log
        exit 1
    fi
}

main(){
    mkdir -p /root/logs
    touch /root/logs/informe_nest.log
    load_entrypoint_nginx
    load_entrypoint_seguridad
    workdir
    dependencias-y-servicio
}

main
