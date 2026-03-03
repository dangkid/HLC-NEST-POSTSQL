#!/bin/bash

load_entrypoint_nginx(){
    /root/admin/sweb/nginx/damgstart.sh
    echo "Entrypoint nginx cargado" >> /root/logs/node_next/node_next.log
}

config_next(){
    echo "Configurando dependencias en node_next" >> /root/logs/node_next/node_next.log
    cd /root/admin/node_next/next-pokeapi
    npm install
    echo "Dependencias de Node instaladas" >> /root/logs/node_next/node_next.log
}

main(){
    mkdir -p /root/logs/node_next
    touch /root/logs/node_next/node_next.log
    load_entrypoint_nginx
    config_next
}

main
