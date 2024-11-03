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
  admin_username      = "worker_user"

  network_interface_ids = [
    azurerm_network_interface.worker_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = "worker_user"
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

  custom_data = base64encode(<<-EOT
    #cloud-config
    package_update: true
    packages:
      - nginx
    write_files:
      - path: /var/www/html/index.html
        content: |
          ${file("${path.module}/../templates/worker_template.html")}
    runcmd:
      - systemctl start nginx
      - systemctl enable nginx
  EOT
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

# Define la lista de servidores de backend en una variable local
locals {
  nginx_backend_servers = join("\n", [for id in range(var.worker_count) : "server ${var.prefix}-worker-${id + 1}:80;"])
}

# Crear máquina virtual para el balanceador
resource "azurerm_linux_virtual_machine" "lb" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "lb_user"

  network_interface_ids = [
    azurerm_network_interface.lb_nic.id,
  ]

  admin_ssh_key {
    username   = "lb_user"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    name                 = "sistema-operativo-lb"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOT
    #cloud-config
    package_update: true
    packages:
      - nginx
    write_files:
      - path: /etc/nginx/nginx.conf
        content: |
          ${templatefile("${path.module}/../templates/lb_nginx.conf", {
    nginx_backend_servers = local.nginx_backend_servers,
    domain_name           = azurerm_public_ip.lb_public_ip.fqdn
})}
    runcmd:
      - systemctl start nginx
      - systemctl enable nginx
      - systemctl restart nginx
    EOT
)
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
  domain_name_label   = "${var.prefix}-lb" # Nombre del DNS
}

# Regla de seguridad de red para permitir SSH al balanceador
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

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.2.0/24"
  }
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