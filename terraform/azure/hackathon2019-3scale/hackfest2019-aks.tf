terraform {
  backend "local" {
    path = ".terraform/state/aks.tfstate"
  }
}

provider "azurerm" {
  version = "=1.34.0"
}

resource "azurerm_resource_group" "aks" {
  name     = "aks-hackfest2019-rg"
  location = "West Europe"
}

module "aks" {
  source         = "../modules/azure/container/aks"
  resource_group = "${azurerm_resource_group.aks}"
  name           = "hackfest2019"
}

output "az-cluster-login" {
  description = "AZ CLI command to get cluster credentiales and set kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${module.aks.cluster_name}"
}
