#!/bin/bash

# Crear el directorio
mkdir -p escribir
cd escribir

WORKER_NAME=$(hostname)
# Crear el archivo y escribir contenido en él
echo "Este es el contenido de prueba en archivo.txt en $WORKER_NAME" > archivo.txt
