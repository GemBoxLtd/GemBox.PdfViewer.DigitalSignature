output "container_ipv4_address" {
  value = azurerm_container_group.container_group.ip_address
}

output "container_fqdn" {
  value = azurerm_container_group.container_group.fqdn
}