#!/bin/bash

# Cambiar al directorio raíz del proyecto
cd "$(dirname "$0")"

# Asegurar los permisos de los scripts, plantillas y configuraciones
chmod +x deploy.sh scripts/*.sh
chmod 644 templates/*

# Función para manejar errores
handle_error() {
    echo "Error: $1"
    echo "Por favor, revisa los logs y la configuración."
    exit 1
}

# Verificar dependencias
command -v az >/dev/null 2>&1 || { echo >&2 "Azure CLI (az) no está instalado. Por favor, instálalo."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo >&2 "Terraform no está instalado. Por favor, instálalo."; exit 1; }

# Comprobar si se ha iniciado sesión en Azure
echo "Comprobando la sesión de Azure..."
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo "No se ha iniciado sesión en Azure. Iniciando sesión..."
    az login
    if [ $? -ne 0 ]; then
        handle_error "No se pudo iniciar sesión en Azure"
    fi
else
    echo "Sesión de Azure activa"
fi

# Solicitar la ruta de la clave SSH pública
read -p "Introduce la ruta de tu clave SSH pública (deja en blanco para usar ~/.ssh/id_rsa.pub): " SSH_KEY_PATH

# Si no se proporciona una ruta, usar el valor por defecto
if [ -z "$SSH_KEY_PATH" ]; then
    SSH_KEY_PATH="~/.ssh/id_rsa.pub"
fi

# Expandir el tilde (~) si está presente
SSH_KEY_PATH=$(eval echo "$SSH_KEY_PATH")

# Verificar si existe la clave SSH pública y sus permisos
if [ -f "$SSH_KEY_PATH" ]; then
    chmod 644 "$SSH_KEY_PATH"
    echo "Permisos correctos otorgados a la clave pública SSH"
else
    handle_error "Clave pública SSH no encontrada en $SSH_KEY_PATH"
fi

# Verificar si se solicita destruir la infraestructura
if [ "$1" = "destroy" ]; then
    echo "Destruyendo la infraestructura..."
    (cd terraform && terraform destroy -auto-approve)
    if [ $? -ne 0 ]; then
        handle_error "Error al destruir la infraestructura"
    fi
    echo "Infraestructura destruida exitosamente"
    exit 0
fi

echo "Iniciando despliegue..."

# Cambiar al directorio de Terraform
cd terraform

# Inicializar Terraform
echo "Inicializando Terraform..."
terraform init
if [ $? -ne 0 ]; then
    handle_error "Error al inicializar Terraform"
fi

# Crear un plan de Terraform
echo "Creando plan de Terraform..."
terraform plan -var="ssh_public_key_path=$SSH_KEY_PATH" -out tfplan
if [ $? -ne 0 ]; then
    handle_error "Error al crear el plan de Terraform"
fi

# Aplicar la configuración de Terraform
echo "Aplicando la configuración de Terraform..."
terraform apply tfplan
if [ $? -ne 0 ]; then
    handle_error "Error al aplicar la configuración de Terraform"
fi

# Obtener la IP pública del balanceador
echo "Obteniendo la IP pública del balanceador..."
LB_IP=$(terraform output -raw lb_public_ip)
if [ -z "$LB_IP" ]; then
    handle_error "No se pudo obtener la IP del balanceador"
fi

echo "Despliegue completado exitosamente"
echo "Balanceador de carga desplegado en: $LB_IP"
echo "Puede acceder al balanceador vía SSH con: ssh lb_user@$LB_IP"

# Mostrar información adicional
echo "Para destruir la infraestructura, ejecute: $0 destroy"

# Volver al directorio raíz del proyecto
cd ..

# Asegurar permisos de los test
chmod +x test_workers.sh

# Ejecutar pruebas de workers
echo "Ejecutando pruebas de los workers..."
./test_workers.sh