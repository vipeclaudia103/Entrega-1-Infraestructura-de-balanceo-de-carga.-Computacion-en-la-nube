#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Mover el archivo HTML a la ubicación correcta
sudo mv /scripts/worker_template.html /var/www/html/index.html

# Reiniciar Nginx para aplicar la nueva configuración
sudo systemctl restart nginx