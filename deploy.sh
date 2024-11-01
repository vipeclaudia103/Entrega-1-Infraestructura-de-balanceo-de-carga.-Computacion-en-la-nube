#!/bin/bash

# Cambiar al directorio raíz del proyecto (asumiendo que deploy.sh está en la raíz)
cd "$(dirname "$0")"

# Función para manejar errores
handle_error() {
    echo "Error: $1"
    exit 1
}

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

# Verificar si configure_worker.sh existe y darle permisos de ejecución
if [ -f scripts/configure_worker.sh ]; then
    chmod +x scripts/configure_worker.sh
    echo "Permisos de ejecución otorgados a configure_worker.sh"
else
    handle_error "configure_worker.sh no encontrado"
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
terraform plan -out tfplan
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

# Volver al directorio raíz
cd ..