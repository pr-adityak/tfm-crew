output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet (waits for NAT Gateway association)"
  # CRITICAL: Reference the NAT Gateway association to ensure egress is configured
  # before any resources (especially AKS) can use this subnet.
  # Without this, AKS nodes may be provisioned without outbound connectivity,
  # causing VMExtensionError_K8SAPIServerConnFail.
  value = azurerm_subnet_nat_gateway_association.aks.subnet_id
}

output "appgw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = azurerm_subnet.appgw.id
}

output "postgres_subnet_id" {
  description = "ID of the PostgreSQL subnet"
  value       = azurerm_subnet.postgres.id
}

output "aks_subnet_address_prefix" {
  description = "Address prefix of the AKS subnet"
  value       = var.aks_subnet_address_prefix
}

output "postgres_subnet_address_prefix" {
  description = "Address prefix of the PostgreSQL subnet"
  value       = var.postgres_subnet_address_prefix
}

output "aks_nsg_id" {
  description = "ID of the AKS network security group"
  value       = azurerm_network_security_group.aks.id
}

output "appgw_nsg_id" {
  description = "ID of the Application Gateway network security group"
  value       = azurerm_network_security_group.appgw.id
}

output "postgres_nsg_id" {
  description = "ID of the PostgreSQL network security group"
  value       = azurerm_network_security_group.postgres.id
}

output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "application_gateway_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = azurerm_public_ip.appgw.ip_address
}

output "application_gateway_public_ip_fqdn" {
  description = "FQDN of the Application Gateway public IP"
  value       = azurerm_public_ip.appgw.fqdn
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway (required for authorized_ip_ranges)"
  value       = azurerm_public_ip.nat.ip_address
}
