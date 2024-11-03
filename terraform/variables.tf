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
  default     = "entregacompu-rg"
}

variable "worker_count" {
  description = "Número de workers a crear"
  default     = 3
}
variable "ssh_public_key_path" {
  description = "Ruta al archivo de clave publica SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub" # Valor por defecto
}
variable "ssh_private_key_path" {
  description = "Ruta al archivo de clave privada SSH"
  type        = string
  default     = "~/.ssh/id_rsa" # Valor por defecto

}
variable "ssh_username" {
  default = "debian127"
}