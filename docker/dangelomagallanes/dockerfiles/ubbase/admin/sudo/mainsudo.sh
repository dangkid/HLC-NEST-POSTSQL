#!/bin/bash

configurar_sudo() {
  echo "Configurando sudo para dangelo..." >> /root/logs/informe.log
  
  if [ -d /etc/sudoers.d ]; then
    echo "dangelo ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/dangelo"
    chmod 0440 "/etc/sudoers.d/dangelo"
    echo "Sudo configurado" >> /root/logs/informe.log
  else
    echo "ERROR: /etc/sudoers.d no existe" >> /root/logs/informe.log
  fi
}
