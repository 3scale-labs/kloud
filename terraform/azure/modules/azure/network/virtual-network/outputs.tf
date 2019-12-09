output "network_id" {
  value = "${azurerm_virtual_network.main.id}"
}
output "compute_subnet_id" {
  value = "${azurerm_subnet.compute.id}"
}
