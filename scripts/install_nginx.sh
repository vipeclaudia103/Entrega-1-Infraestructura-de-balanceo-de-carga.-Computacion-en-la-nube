#!/bin/bash

# Función para manejar errores
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Actualizar la lista de paquetes
echo "Actualizando lista de paquetes..."
sudo apt-get update || handle_error "No se pudo actualizar la lista de paquetes"

# Instalar Nginx
echo "Instalando Nginx..."
sudo apt-get install -y nginx || handle_error "No se pudo instalar Nginx"

# Verificar que Nginx se ha instalado correctamente
if ! command -v nginx &> /dev/null; then
    handle_error "Nginx no se instaló correctamente"
fi

# Iniciar el servicio Nginx
echo "Iniciando el servicio Nginx..."
sudo systemctl start nginx || handle_error "No se pudo iniciar el servicio Nginx"

# Habilitar Nginx para que se inicie con el sistema
echo "Habilitando Nginx para que se inicie con el sistema..."
sudo systemctl enable nginx || handle_error "No se pudo habilitar Nginx para iniciar con el sistema"

# Verificar el estado de Nginx
echo "Verificando el estado de Nginx..."
sudo systemctl status nginx || handle_error "Nginx no está funcionando correctamente"

# Configurar el firewall (si está en uso)
echo "Configurando el firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw allow 'Nginx HTTP' || handle_error "No se pudo configurar el firewall para Nginx"
fi

echo "Nginx se ha instalado y configurado correctamente"