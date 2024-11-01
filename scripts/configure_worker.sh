#!/bin/bash

# Asegurar permisos de install_nginx.sh
chmod +x install_nginx.sh
# Instalar Nginx
./install.sh

# Obtiene el hostname del worker
WORKER_NAME=$(hostname)
# Configurar página personalizada
sed "s/WORKER_NAME/$WORKER_NAME/" /tmp/worker_template.html > /var/www/html/index.html

# Reiniciar Nginx
systemctl restart nginx