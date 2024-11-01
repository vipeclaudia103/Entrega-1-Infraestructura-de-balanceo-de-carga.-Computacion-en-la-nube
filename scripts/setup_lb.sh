#!/bin/bash

# Instalar Nginx
apt-get update
apt-get install -y nginx

# Copiar la configuración de Nginx
cat > /etc/nginx/nginx.conf <<EOL
${nginx_config}
EOL

# Reiniciar Nginx para aplicar la configuración
systemctl restart nginx