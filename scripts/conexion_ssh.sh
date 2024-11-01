#!/bin/bash

LB_IP=$(terraform -chdir=terraform output -raw lb_public_ip)

eval $(ssh-agent -s)
ssh-add ~/.ssh/id_rsa

ssh -i ~/.ssh/id_rsa lb_user@$LB_IP