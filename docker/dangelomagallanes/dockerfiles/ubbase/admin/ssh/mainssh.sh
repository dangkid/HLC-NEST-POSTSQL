#!/bin/bash

configurar_ssh() {
  echo "Configurando SSH..." >> /root/logs/informe.log
  if [ -f /etc/ssh/sshd_config ]; then
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#Port.*/Port 3456/' /etc/ssh/sshd_config
  fi
  
  mkdir -p /run/sshd
  mkdir -p /home/dangelo/.ssh
  
  if [ -f /root/admin/base/common/id_rsa.pub ]; then
    cat /root/admin/base/common/id_rsa.pub >> /home/dangelo/.ssh/authorized_keys
    echo "Clave SSH añadida" >> /root/logs/informe.log
  fi
  
  if command -v /usr/sbin/sshd &> /dev/null; then
    exec /usr/sbin/sshd -D &
    echo "SSH configurado y funcionando" >> /root/logs/informe.log
  else
    echo "ERROR: sshd no encontrado" >> /root/logs/informe.log
  fi
}
