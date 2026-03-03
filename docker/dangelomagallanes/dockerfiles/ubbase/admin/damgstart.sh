#!/bin/bash

set -e

source /root/admin/base/usuario/mainuser.sh
source /root/admin/base/ssh/mainssh.sh
source /root/admin/base/sudo/mainsudo.sh

main (){
    mkdir -p /root/logs
    touch /root/logs/informe.log
    crear_usuario
    resuser=$?
    if [ "$resuser" -eq 0 ]; then
        configurar_sudo
    fi
    if [ "$resuser" -eq 0 ]; then
        configurar_ssh
    fi
}

main
