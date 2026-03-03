#!/bin/bash

comprobar_usuario(){
    if grep -q "^dangelo:" /etc/passwd 
    then
        echo "El usuario dangelo ya existe." >> /root/logs/informe.log
        return 1
    else
        echo "El usuario dangelo no existe. Creando usuario..." >> /root/logs/informe.log
        return 0
    fi
}

comprobar_directorio(){
    if [ ! -d "/home/dangelo" ]
    then
        echo "El directorio /home/dangelo no existe." >> /root/logs/informe.log
        return 0
    else
        echo "El directorio /home/dangelo ya existe." >> /root/logs/informe.log
        return 1
    fi
}

crear_usuario(){
    comprobar_usuario
    if [ $? -eq 0 ]
    then
        comprobar_directorio
        if [ $? -eq 0 ]
        then
            useradd -rm -d /home/dangelo -s /bin/bash dangelo
            echo "dangelo:1234" | chpasswd
            echo "Bienvenido dangelo" > /home/dangelo/welcome.txt
            echo "Usuario dangelo creado con éxito." >> /root/logs/informe.log
            return 0
        else
            echo "No se puede crear el usuario dangelo porque el directorio ya existe." >> /root/logs/informe.log
            return 1
        fi
    else
        echo "No se puede crear el usuario dangelo porque ya existe." >> /root/logs/informe.log
        return 1
    fi
}
