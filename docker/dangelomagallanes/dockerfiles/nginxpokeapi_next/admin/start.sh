#!/bin/bash

load_entrypoint_node(){
    bash /root/admin/node_next/start.sh
    echo "Entrypoint node cargado" >> /root/logs/next_final/next_final.log
}

load_entrypoint_ubseguridad(){
    bash /root/admin/ubseguridad/damgstart.sh
    echo "Entrypoint seguridad cargado" >> /root/logs/next_final/next_final.log
}

cofiguracion_final_nginx(){
    # 1. Aplicar la configuración de Nginx (para escuchar en 80)
    cp /root/admin/nginxpokeapi_next/nginx.conf /etc/nginx/sites-available/default
    
    cd /root/admin/node_next/next-pokeapi
    
    # Limpiar caché y dependencias de otros entornos
    rm -rf node_modules package-lock.json .next
    npm install
    
    # Fix permisos de ejecución para next
    chmod +x node_modules/.bin/next
    # 2. Compilar Next.js (output: export estático)
    npm run build
    
    # 2.5 Mover los archivos del export a Nginx
    cp -r /root/admin/node_next/next-pokeapi/out/* /var/www/html/
    chown -R www-data:www-data /var/www/html/
    chmod -R 755 /var/www/html/
    echo "Next.js compilado e instalado en /var/www/html" >> /root/logs/next_final/next_final.log
    
    # 3. Mover página de error personalizada
    cp /root/admin/node_next/error.html /var/www/html/error.html
    echo "Página de error copiada a /var/www/html" >> /root/logs/next_final/next_final.log
    
    # 4. Iniciar Nginx en primer plano
    echo "Nginx iniciado en primer plano (Proxy)" >> /root/logs/next_final/next_final.log
    nginx -g "daemon off;"
}

main(){
    mkdir -p /root/logs/next_final
    touch /root/logs/next_final/next_final.log
    load_entrypoint_ubseguridad
    load_entrypoint_node
    cofiguracion_final_nginx
}

main
