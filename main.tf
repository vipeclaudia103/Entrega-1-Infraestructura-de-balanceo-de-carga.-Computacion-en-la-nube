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
