#!/bin/bash

sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Define la ruta del archivo index.html
INDEX_FILE="/var/www/html/index.html"

# Verifica si el archivo existe
if [ ! -f "$INDEX_FILE" ]; then
  echo "El archivo $INDEX_FILE no existe. Creándolo..."
  touch "$INDEX_FILE"
fi

 # Obtener el nombre de host y crear el archivo HTML con expansión de variables
    HOSTNAME=$(hostname)

    # Generar el archivo index.html con el nombre de host expandido
    echo "<!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Worker ${HOSTNAME}</title>
    </head>
    <body>
        <h1>Bienvenido al Worker ${HOSTNAME}</h1>
        <p>Respuesta por el servidor Nginx en el worker ${HOSTNAME}.</p>
    </body>
    </html>" > "$INDEX_FILE"

# Reinicia Nginx para aplicar los cambios
systemctl restart nginx

echo "Contenido de $INDEX_FILE actualizado y Nginx reiniciado."
