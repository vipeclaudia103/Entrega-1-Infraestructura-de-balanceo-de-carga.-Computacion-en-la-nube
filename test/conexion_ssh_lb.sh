#!/bin/bash

LB_IP=$(terraform -chdir=terraform output -raw lb_public_ip)

# Reinicia el agente SSH
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

# Intentar conexión
ssh -i ~/.ssh/id_rsa lb_user@$LB_IP

# LB =$(who)
# if [ "$LB" = "lb_user" ]; then
#     chmod 644 "$SSH_KEY_PATH"
#     echo "Permisos correctos otorgados a la clave pública SSH"
# else
#     handle_error "Clave pública SSH no encontrada en $SSH_KEY_PATH"
# fi
# Verificar el estado del servicio Nginx:
# sudo systemctl status nginx