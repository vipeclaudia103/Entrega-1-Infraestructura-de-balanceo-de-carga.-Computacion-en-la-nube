#!/bin/bash

# Navega al directorio de Terraform
cd ../terraform || exit 1

# Solicita el número del worker (ajustado para que empiece desde 0)
read -p "Introduce el número del worker (1 para el primero): " WORKER_N
WORKER_N=$((WORKER_N - 1))  # Convertir a índice 0

# Obtener IP pública del balanceador
LB_IP=$(terraform output -raw lb_public_ip)

# Obtener IP privada y nombre del worker especificado usando -json
WK_IP=$(terraform output -json ip_workers | jq -r ".[$WORKER_N]")
WK_NAME=$(terraform output -json nombre_workers | jq -r ".[$WORKER_N]")

# Comprobación de valores obtenidos
if [[ -z "$WK_IP" || -z "$WK_NAME" ]]; then
  echo "No se pudo obtener la IP o el nombre del worker. Verifica que el índice ingresado es correcto."
  exit 1
fi

# Preparar conexión SSH
chmod 600 ~/.ssh/id_rsa
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

# Conectar al worker usando SSH
ssh -i ~/.ssh/id_rsa -J lb_user@$LB_IP $WK_NAME@$WK_IP
