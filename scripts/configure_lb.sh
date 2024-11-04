#!/bin/bash
sudo dpkg --configure -a
sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

    echo 'events {
      worker_connections 1024;
    }

    http {
        upstream backend {
            server 10.0.1.4;
            server 10.0.1.5;
            server 10.0.1.6;
        }

        server {
            listen 80;
            server_name entregacompu-lb;

            location / {
                proxy_pass http://backend;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
            }
        }
    }
    ' | sudo tee /etc/nginx/nginx.conf
# Verificar que Nginx está funcionando correctamente    
sudo nginx -t
sudo systemctl enable nginx
# Reiniciar Nginx para aplicar la nueva configuración
sudo systemctl restart nginx


