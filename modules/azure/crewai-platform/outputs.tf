output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "network_configuration" {
  description = "Network configuration outputs"
  value = {
    vnet_id                        = module.networking.vnet_id
    vnet_name                      = module.networking.vnet_name
    aks_subnet_id                  = module.networking.aks_subnet_id
    appgw_subnet_id                = module.networking.appgw_subnet_id
    postgres_subnet_id             = module.networking.postgres_subnet_id
    aks_subnet_address_prefix      = module.networking.aks_subnet_address_prefix
    postgres_subnet_address_prefix = module.networking.postgres_subnet_address_prefix
    application_gateway_id         = module.networking.application_gateway_id
    application_gateway_name       = module.networking.application_gateway_name
    application_gateway_public_ip  = module.networking.application_gateway_public_ip
  }
}

output "cluster_configuration" {
  description = "Cluster configuration outputs"
  value = {
    cluster_name               = module.cluster.cluster_name
    cluster_fqdn               = module.cluster.cluster_fqdn
    kubelet_identity_client_id = module.cluster.kubelet_identity_client_id
    node_resource_group        = module.cluster.node_resource_group
    oidc_issuer_url            = module.cluster.oidc_issuer_url
  }
  sensitive = false
}

output "database_configuration" {
  description = "Database configuration outputs"
  value = {
    server_name         = module.database.server_name
    server_fqdn         = module.database.server_fqdn
    database_name       = module.database.database_name
    administrator_login = module.database.administrator_login
    replica_fqdns       = module.database.replica_fqdns
  }
  sensitive = false
}

output "storage_configuration" {
  description = "Storage configuration outputs"
  value = {
    data_storage_account_name = module.storage.data_storage_account_name
    logs_storage_account_name = module.storage.logs_storage_account_name
    data_container_name       = module.storage.data_container_name
    logs_container_name       = module.storage.logs_container_name
  }
}

output "secrets_configuration" {
  description = "Secrets configuration outputs"
  value = {
    key_vault_name = module.secrets.key_vault_name
    key_vault_uri  = module.secrets.key_vault_uri
  }
}

output "db_password" {
  description = "Database password (store securely, do not log)"
  value       = module.secrets.db_password
  sensitive   = true
}

output "repository_configuration" {
  description = "Repository configuration outputs"
  value = {
    registry_name         = module.repository.registry_name
    registry_login_server = module.repository.registry_login_server
  }
}

output "kube_config" {
  description = "Kubernetes configuration (for kubectl access)"
  value       = module.cluster.kube_config
  sensitive   = true
}

output "kubernetes_host" {
  description = "Kubernetes API server host"
  value       = module.cluster.kube_config_host
  sensitive   = true
}

output "kubernetes_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate (base64 encoded)"
  value       = module.cluster.kube_config_cluster_ca_certificate
  sensitive   = true
}

output "kubernetes_client_certificate" {
  description = "Kubernetes client certificate (base64 encoded)"
  value       = module.cluster.kube_config_client_certificate
  sensitive   = true
}

output "kubernetes_client_key" {
  description = "Kubernetes client key (base64 encoded)"
  value       = module.cluster.kube_config_client_key
  sensitive   = true
}
