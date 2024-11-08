#!/bin/bash

# cd "$(dirname "$0")"
# cd terraform

# Obtener la IP pública del balanceador desde la salida de Terraform
LB_IP=$(terraform output -raw lb_public_ip)

# Verificar si la IP fue obtenida correctamente
if [ -z "$LB_IP" ]; then
  echo "Error: No se pudo obtener la IP pública del balanceador."
  exit 1
fi

# Reiniciar el agente SSH y agregar la clave
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

# Intentar la conexión SSH
ssh -i ~/.ssh/id_rsa lb_user@$LB_IP


