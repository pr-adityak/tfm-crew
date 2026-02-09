# Get current client configuration
data "azurerm_client_config" "current" {}

# Centralized random suffix for globally unique resource names
# Azure requires unique names for storage accounts, key vaults, and container registries.
# Using a single suffix ensures consistent naming across the deployment.
resource "random_id" "deployment" {
  byte_length = 4
}

# Merge NAT Gateway IP with provided authorized IP ranges
# Required: Pods egress via NAT Gateway to reach the API server.
# Without the NAT Gateway IP in authorized_ip_ranges, pods cannot
# communicate with the Kubernetes API server when IP restrictions are enabled.
# See: https://learn.microsoft.com/en-us/azure/aks/api-server-authorized-ip-ranges
locals {
  # Centralized suffix for all globally-unique resource names
  resource_suffix = random_id.deployment.hex

  all_authorized_ip_ranges = distinct(concat(
    var.authorized_ip_ranges,
    ["${module.networking.nat_gateway_public_ip}/32"]
  ))
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Networking Module (includes Application Gateway)
module "networking" {
  source = "../networking"

  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  vnet_name                = var.vnet_name
  vnet_address_space       = var.vnet_address_space
  application_gateway_name = var.application_gateway_name

  tags = var.tags
}

# Storage Module
module "storage" {
  source = "../storage"

  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  data_storage_account_name = var.data_storage_account_name
  logs_storage_account_name = var.logs_storage_account_name
  resource_suffix           = local.resource_suffix
  vnet_id                   = module.networking.vnet_id
  subnet_id                 = module.networking.aks_subnet_id

  tags = var.tags

  depends_on = [module.networking]
}

# Secrets Module
module "secrets" {
  source = "../secrets"

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  key_vault_name       = var.key_vault_name
  resource_suffix      = local.resource_suffix
  tenant_id            = data.azurerm_client_config.current.tenant_id
  vnet_id              = module.networking.vnet_id
  subnet_id            = module.networking.aks_subnet_id
  authorized_ip_ranges = local.all_authorized_ip_ranges

  tags = var.tags

  depends_on = [module.networking]
}

# Repository Module
module "repository" {
  source = "../repository"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  registry_name       = var.acr_name
  resource_suffix     = local.resource_suffix

  tags = var.tags
}

# Database Module
module "database" {
  source = "../database"

  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  server_name            = var.db_server_name
  administrator_login    = var.db_administrator_login
  administrator_password = module.secrets.db_password
  database_name          = var.db_name
  delegated_subnet_id    = module.networking.postgres_subnet_id
  vnet_id                = module.networking.vnet_id
  reader_instance_count  = var.db_reader_instance_count

  tags = var.tags

  depends_on = [
    module.networking,
    module.secrets
  ]
}

# Cluster Module
module "cluster" {
  source = "../cluster"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  cluster_name            = var.cluster_name
  kubernetes_version      = var.kubernetes_version
  aks_subnet_id           = module.networking.aks_subnet_id
  authorized_ip_ranges    = local.all_authorized_ip_ranges
  acr_id                  = module.repository.registry_id
  key_vault_id            = module.secrets.key_vault_id
  data_storage_account_id = module.storage.data_storage_account_id
  logs_storage_account_id = module.storage.logs_storage_account_id

  tags = var.tags

  depends_on = [
    module.networking,
    module.repository,
    module.secrets,
    module.storage
  ]
}
