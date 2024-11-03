output "lb_public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

output "lb_fqdn" {
  value = azurerm_public_ip.lb_public_ip.fqdn
}

output "first_worker_ip" {
  value = azurerm_linux_virtual_machine.worker[0].private_ip_address
}