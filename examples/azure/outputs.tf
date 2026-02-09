output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.crewai_platform.resource_group_name
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.crewai_platform.cluster_configuration.cluster_name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.crewai_platform.cluster_configuration.cluster_fqdn
}

output "database_server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = module.crewai_platform.database_configuration.server_fqdn
}

output "database_name" {
  description = "Name of the database"
  value       = module.crewai_platform.database_configuration.database_name
}

output "registry_login_server" {
  description = "Login server URL for Azure Container Registry"
  value       = module.crewai_platform.repository_configuration.registry_login_server
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = module.crewai_platform.network_configuration.application_gateway_public_ip
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.crewai_platform.secrets_configuration.key_vault_uri
}

output "data_storage_account_name" {
  description = "Name of the data storage account"
  value       = module.crewai_platform.storage_configuration.data_storage_account_name
}

output "logs_storage_account_name" {
  description = "Name of the logs storage account"
  value       = module.crewai_platform.storage_configuration.logs_storage_account_name
}

output "configure_kubectl_command" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group ${module.crewai_platform.resource_group_name} --name ${module.crewai_platform.cluster_configuration.cluster_name}"
}
