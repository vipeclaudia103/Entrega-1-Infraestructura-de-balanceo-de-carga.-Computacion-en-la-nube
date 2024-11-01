#!/bin/bash

# Instalar Nginx
apt-get update
apt-get install -y nginx

# Configurar página personalizada
WORKER_NAME=$(hostname)
sed "s/WORKER_NAME/$WORKER_NAME/" /tmp/worker_template.html > /var/www/html/index.html

# Reiniciar Nginx
systemctl restart nginx