resource "azurerm_resource_group" "aks" {
  name     = "aks-hackfest2019-rg"
  location = "West Europe"
}

module "aks" {
  source         = "../modules/azure/container/aks"
  resource_group = "${azurerm_resource_group.aks}"
  name           = "hackfest2019"
}

resource "azurerm_dns_zone" "az_mc" {
  name                = "az.mc.3sca.net"
  resource_group_name = "${azurerm_resource_group.aks.name}"
}

resource "azurerm_dns_a_record" "az_mc_wildcard" {
  name                = "*"
  zone_name           = "${azurerm_dns_zone.az_mc.name}"
  resource_group_name = "${azurerm_resource_group.aks.name}"
  ttl                 = 300
  records             = ["52.166.37.118"] # aks traefik load balancer ip

}

output "az-cluster-login" {
  description = "AZ CLI command to get cluster credentiales and set kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${module.aks.cluster_name}"
}

output "az-dns-zone" {
  description = "Azure Hackathon2019 dns zone"
  value       = "${azurerm_dns_zone.az_mc.name_servers}"
}
