#!/bin/bash

# Instalar Nginx
apt-get update
apt-get install -y nginx

# Obtiene el hostname del worker
WORKER_NAME=$(hostname)
# Configurar página personalizada
sed "s/WORKER_NAME/$WORKER_NAME/" /tmp/worker_template.html > /var/www/html/index.html

# Reiniciar Nginx
systemctl restart nginx