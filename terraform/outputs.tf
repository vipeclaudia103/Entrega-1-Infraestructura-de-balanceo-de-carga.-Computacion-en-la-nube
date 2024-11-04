output "lb_public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

output "lb_dns_name" {
  value = azurerm_public_ip.lb_public_ip.fqdn
  description = "El nombre de dominio completo asignado a la IP pública del balanceador."
}

output "first_worker_ip" {
  value = azurerm_linux_virtual_machine.worker[0].private_ip_address
}
output "ip_workers" {
  value = [for vm in azurerm_linux_virtual_machine.worker : vm.private_ip_address]
}
