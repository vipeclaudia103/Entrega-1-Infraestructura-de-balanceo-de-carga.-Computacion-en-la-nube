#!/bin/bash

cd ../terraform || exit 1

# Obtener las IPs y nombres de los workers
LB_IP=$(terraform output -raw lb_public_ip)
IP_WORKERS=$(terraform output -json ip_workers | jq -r ".[]")
NOMBRE_WORKERS=$(terraform output -json nombre_workers | jq -r ".[]")

# Ruta del archivo local a copiar y ruta remota
LOCAL_FILE_PATH="../scripts/configure_worker.sh"  # Cambia a la ruta correcta si es necesario
REMOTE_FILE_NAME="configure_worker.sh"

# Configurar el agente SSH
chmod 600 ~/.ssh/id_rsa
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

# Bucle para conectarse a cada worker y ejecutar el archivo
index=0
for WK_IP in $IP_WORKERS; do
  WK_NAME=$(echo "$NOMBRE_WORKERS" | sed -n "$((index + 1))p")
  
  echo "Conectando al worker $((index + 1)): $WK_NAME@$WK_IP"
  
  # Copiar el archivo local al directorio de inicio del usuario remoto
  scp -i ~/.ssh/id_rsa -o ProxyJump=lb_user@$LB_IP "$LOCAL_FILE_PATH" "$WK_NAME@$WK_IP:/home/$WK_NAME/$REMOTE_FILE_NAME"
  
  # Conectar y ejecutar el archivo en la máquina remota
  ssh -i ~/.ssh/id_rsa -J lb_user@$LB_IP $WK_NAME@$WK_IP << EOF
    # Dar permisos de ejecución al archivo
    chmod +x /home/$WK_NAME/$REMOTE_FILE_NAME
    
    # Ejecutar el archivo con sudo
    sudo /home/$WK_NAME/$REMOTE_FILE_NAME
EOF

  echo "Archivo ejecutado en el worker $((index + 1))"
  index=$((index + 1))
done
