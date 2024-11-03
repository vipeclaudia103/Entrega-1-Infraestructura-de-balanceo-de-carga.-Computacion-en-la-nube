#!/bin/bash

LB_IP=$(terraform -chdir=terraform output -raw lb_public_ip)
WK_IP=$(terraform output -raw first_worker_ip)
echo $WK_IP
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

ssh -i ~/.ssh/id_rsa -J lb_user@$LB_IP debian127-worker-1@$WK_IP