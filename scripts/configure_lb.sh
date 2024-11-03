#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
# Mover el archivo de configuración de Nginx
sudo mv lb_nginx.conf /etc/nginx/nginx.conf

# Reiniciar Nginx para aplicar la nueva configuración
sudo systemctl restart nginx

# Verificar que Nginx está funcionando correctamente
sudo nginx -t && echo "Nginx configuration test passed" || echo "Nginx configuration test failed"