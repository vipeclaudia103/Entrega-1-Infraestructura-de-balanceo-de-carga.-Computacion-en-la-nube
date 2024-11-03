#!/bin/bash

# Mover el archivo de configuración de Nginx
sudo mv /tmp/worker_nginx.conf /etc/nginx/nginx.conf

# Mover el archivo HTML a la ubicación correcta
sudo mv /tmp/index.html /var/www/html/index.html

# Reiniciar Nginx para aplicar la nueva configuración
sudo systemctl restart nginx