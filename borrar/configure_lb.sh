#!/bin/bash

#!/bin/bash

# Mover el archivo de configuración de Nginx
sudo mv /tmp/lb_nginx.conf /etc/nginx/nginx.conf

# Reiniciar Nginx para aplicar la nueva configuración
sudo systemctl restart nginx

# Verificar que Nginx está funcionando correctamente
sudo nginx -t && echo "Nginx configuration test passed" || echo "Nginx configuration test failed"