#!/bin/bash

LB_IP=$(terraform -chdir=terraform output -raw lb_public_ip)

echo "Probando el balanceador de carga en $LB_IP"
for i in {1..10}; do
  echo "Petición $i:"
  curl -s http://$LB_IP
  echo ""
  sleep 1
done