#!/bin/bash

# Instala Git LFS si no está instalado
if ! command -v git-lfs &> /dev/null; then
    echo "Instalando Git LFS..."
    sudo apt update && sudo apt install git-lfs -y
fi

# Inicializa Git LFS
git lfs install

# Configura el archivo grande para que sea rastreado por Git LFS
LARGE_FILE=".terraform/providers/registry.terraform.io/hashicorp/azurerm/4.6.0/linux_amd64/terraform-provider-azurerm_v4.6.0_x5"

echo "Configurando el archivo grande para Git LFS: $LARGE_FILE"
git lfs track "$LARGE_FILE"

# Añade y confirma los cambios en el archivo .gitattributes (creado por Git LFS)
echo "Añadiendo el archivo .gitattributes al commit..."
git add .gitattributes
git commit -m "Configura Git LFS para archivos grandes"

# Añade y confirma el archivo grande a Git LFS
echo "Añadiendo el archivo grande al commit..."
git add "$LARGE_FILE"
git commit -m "Añadir archivo grande a Git LFS"

# Realiza el push al repositorio remoto
echo "Haciendo push de los cambios al repositorio remoto..."
git push origin main
