terraform {
	required_providers {
		azurerm ={
			source = "hashicorp/azurerm"
			version = "~> 4.6.0"
		}
	}
#	required_version = ">= 1.1.0"
}
provider "azurerm" { #configuracion autentificación del servidor
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
  admin_username      = "${var.ssh_username}-worker-${count.index + 1}"

  network_interface_ids = [
    azurerm_network_interface.worker_nic[count.index].id,
  ]

  admin_ssh_key {
    username   = "${var.ssh_username}-worker-${count.index + 1}"
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

  custom_data = base64encode(
    join("\n", [
      file("${path.module}/../templates/worker_template.html"),
    file("${path.module}/scripts/install_nginx.sh"),
    file("${path.module}/scripts/configure_worker.sh")    ])
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
  # Intalación de nginx en la mv del balanceador y configuración con el archivo lb_nginx.conf
  custom_data = base64encode(join("\n", [
    file("${path.module}/scripts/install_nginx.sh"),
    templatefile("${path.module}/scripts/setup_lb.sh", {
      nginx_config = templatefile("${path.module}/templates/lb_nginx.conf", {
        worker_ips = azurerm_network_interface.worker_nic[*].private_ip_address
      })
    })
  ]))
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
    destination_address_prefix = "*"
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
    destination_address_prefix = "*"
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