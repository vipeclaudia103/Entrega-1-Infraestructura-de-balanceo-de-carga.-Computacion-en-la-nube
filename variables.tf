variable "prefix" {
  description = "Prefijo para los nombres de los recursos"
  default     = "entregacompu"
}

variable "location" {
  description = "Ubicación de Azure para los recursos"
  default     = "westus"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  default     = "entrega-rg"
}

variable "worker_count" {
  description = "Número de workers a crear"
  default     = 3
}
variable "ssh_public_key_path" {
  description = "Ruta al archivo de clave pública SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
variable "ssh_username" {
  default = "debian127"
}