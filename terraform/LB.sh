#!/bin/bash

# Obtener la IP pública del balanceador desde la salida de Terraform
LB_IP=$(terraform output -raw lb_public_ip)

# Verificar si la IP fue obtenida correctamente
if [ -z "$LB_IP" ]; then
  echo "Error: No se pudo obtener la IP pública del balanceador."
  exit 1
fi

# Ruta del archivo local a copiar y el nombre que tendrá en el balanceador
LOCAL_FILE_PATH="../scripts/configure_lb.sh"
REMOTE_FILE_NAME="configure_lb.sh"

# Configurar el agente SSH y agregar la clave
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

# Copiar el archivo al directorio de inicio del usuario en el balanceador
scp -i ~/.ssh/id_rsa "$LOCAL_FILE_PATH" lb_user@$LB_IP:/home/lb_user/$REMOTE_FILE_NAME

# Conectarse al balanceador y ejecutar el archivo copiado
ssh -i ~/.ssh/id_rsa lb_user@$LB_IP << EOF
  # Dar permisos de ejecución al archivo
  chmod +x /home/lb_user/$REMOTE_FILE_NAME

  # Ejecutar el archivo con sudo
  sudo /home/lb_user/$REMOTE_FILE_NAME
EOF

echo "Archivo ejecutado en el balanceador de carga"
