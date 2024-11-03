terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.6.0"
    }
  }
  #	required_version = ">= 1.1.0"
}
provider "azurerm" {                                       #configuracion autentificación del servidor
  subscription_id = "da0c0d8c-6754-4741-b160-d019bef4484e" # se saca con az account show, elparametro id
  features {}
}

# Crear grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Crear red virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Crear subred para workers
resource "azurerm_subnet" "worker_subnet" {
  name                 = "worker-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Crear subred para el balanceador
resource "azurerm_subnet" "lb_subnet" {
  name                 = "lb-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Crear máquinas virtuales para workers
resource "azurerm_linux_virtual_machine" "worker" {
  count               = var.worker_count
  name                = "${var.prefix}-worker-${count.index + 1}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "worker-${count.index + 1}"

  network_interface_ids = [
    azurerm_network_interface.worker_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = "worker-${count.index + 1}"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install -y nginx
  echo '<!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Worker ${HOSTNAME}</title>
    </head>

    <body>
        <h1>Bienvenido al Worker ${HOSTNAME}</h1>
        <p>Hola soy el worker ${HOSTNAME}.</p>
    </body>

    </html>' | sudo tee /var/www/html/index.html
  sudo systemctl enable nginx
  sudo systemctl start nginx
  EOF
  )
}

# Crear máquina virtual para el balanceador
resource "azurerm_linux_virtual_machine" "lb" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "lb_user"

  network_interface_ids = [
    azurerm_network_interface.lb_nic.id,
  ]

  admin_ssh_key {
    username   = "lb_user"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
  #!/bin/bash
  sudo apt-get update
  sudo apt-get install -y nginx
  echo 'http {
    upstream backend {
      ${join("\n", [for nic in azurerm_network_interface.worker_nic : "server ${nic.private_ip_address}:80;"])}
    }
    server {
      listen 80;
      location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
      }
    }
  }' | sudo tee /etc/nginx/nginx.conf
  sudo systemctl enable nginx
  sudo systemctl restart nginx
  EOF
  )
}



# Crear NIC para workers
resource "azurerm_network_interface" "worker_nic" {
  count               = var.worker_count
  name                = "${var.prefix}-worker-nic-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.worker_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}



# Crear NIC para el balanceador
resource "azurerm_network_interface" "lb_nic" {
  name                = "${var.prefix}-lb-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = azurerm_subnet.lb_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lb_public_ip.id
  }
}

# Crear IP pública para el balanceador
resource "azurerm_public_ip" "lb_public_ip" {
  name                = "${var.prefix}-lb-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "${var.prefix}-lb"
}

resource "azurerm_network_security_group" "lb_nsg" {
  name                = "${var.prefix}-lb-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.2.0/24"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.2.0/24"
  }
}

resource "azurerm_network_security_group" "worker_nsg" {
  name                = "${var.prefix}-worker-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = azurerm_subnet.lb_subnet.address_prefixes[0]
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowICMPInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "worker_nsg_association" {
  count                     = var.worker_count
  network_interface_id      = azurerm_network_interface.worker_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.worker_nsg.id
}
# Asociar NSG a la NIC del balanceador
resource "azurerm_network_interface_security_group_association" "lb_nsg_association" {
  network_interface_id      = azurerm_network_interface.lb_nic.id
  network_security_group_id = azurerm_network_security_group.lb_nsg.id
}

# Configuración de apagado automático para workers
resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_schedule_worker" {
  count              = var.worker_count
  virtual_machine_id = azurerm_linux_virtual_machine.worker[count.index].id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = "2000" # 8:00 PM en formato de 24 horas
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled         = true
    time_in_minutes = 30
    webhook_url     = "https://sample-webhook-url.example.com"
  }
}

# Configuración de apagado automático para balanceador
resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown_schedule_lb" {
  virtual_machine_id = azurerm_linux_virtual_machine.lb.id
  location           = azurerm_resource_group.rg.location
  enabled            = true

  daily_recurrence_time = "2000" # 8:00 PM en formato de 24 horas
  timezone              = "Romance Standard Time"

  notification_settings {
    enabled         = true
    time_in_minutes = 30
    webhook_url     = "https://sample-webhook-url.example.com"
  }
}