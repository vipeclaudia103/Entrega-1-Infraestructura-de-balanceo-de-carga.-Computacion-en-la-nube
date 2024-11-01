#!/bin/bash

# Asegurar permisos de install_nginx.sh
chmod +x install_nginx.sh
# Instalar Nginx
./install.sh
# Copiar la configuración de Nginx
sudo cat > /etc/nginx/nginx.conf <<EOL
${nginx_config}
EOL

# Reiniciar Nginx para aplicar la configuración
sudo systemctl restart nginx