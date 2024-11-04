#!/bin/bash

LB_IP=$(terraform output -raw lb_public_ip)
echo "http://$LB_IP"
echo "Probando el balanceador de carga en $LB_IP"
for i in {1..5}; do
  echo "Petición $i:"
  curl -s http://$LB_IP
  echo ""
  sleep 1
done

DNS=$(terraform output -raw lb_dns_name)

echo "Probando el balanceador de carga en $DNS"
for i in {1..5}; do
  echo "Petición $i:"
  curl -s http://$DNS
  echo ""
  sleep 1
done