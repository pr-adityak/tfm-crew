terraform {
  required_version = ">= 1.13.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.52"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  # Azure Backend for Remote State Storage
  # REQUIRED: Create storage account before running terraform init (see docs/azure.md)
  # OPTIONAL: Comment out this entire backend block to use local state instead
  backend "azurerm" {
    storage_account_name = "YOUR-UNIQUE-STATE-STORAGE-NAME" # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "crewai/terraform.tfstate"

    use_azuread_auth = true
    use_cli          = true
  }
}

provider "azurerm" {
  subscription_id     = "YOUR-SUBSCRIPTION-ID" # Replace with your Azure subscription ID
  storage_use_azuread = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ============================================================================
# Auto-detection of Terraform runner network
# ============================================================================

# Detect public IP of machine running Terraform
data "http" "terraform_runner_ip" {
  url = "https://checkip.amazonaws.com"

  lifecycle {
    postcondition {
      condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}", chomp(self.response_body)))
      error_message = "Failed to detect valid public IP address"
    }
  }
}

locals {
  # Clean up the detected IP and format as CIDR
  terraform_runner_cidr = "${chomp(data.http.terraform_runner_ip.response_body)}/32"

  # Merge auto-detected IP with user-provided authorized IPs
  all_authorized_ip_ranges = distinct(concat(
    [local.terraform_runner_cidr],
    var.authorized_ip_ranges
  ))
}

# Get current client config
data "azurerm_client_config" "current" {}

# ============================================================================
# CrewAI Platform Module
# This module encapsulates the complete CrewAI platform infrastructure
# ============================================================================

module "crewai_platform" {
  source = "../../modules/azure/crewai-platform"

  # Core Configuration
  resource_group_name = var.resource_group_name
  location            = var.location

  # Network Configuration
  vnet_name          = var.vnet_name
  vnet_address_space = var.vnet_address_space

  # Cluster Configuration
  cluster_name         = var.cluster_name
  kubernetes_version   = var.kubernetes_version
  authorized_ip_ranges = local.all_authorized_ip_ranges

  # Database Configuration
  db_server_name           = var.db_server_name
  db_administrator_login   = var.db_administrator_login
  db_name                  = var.db_name
  db_reader_instance_count = var.db_reader_instance_count

  # Storage Configuration
  data_storage_account_name = var.data_storage_account_name
  logs_storage_account_name = var.logs_storage_account_name

  # Registry Configuration
  acr_name = var.acr_name

  # Secrets Configuration
  key_vault_name = var.key_vault_name

  # Application Gateway Configuration
  application_gateway_name = var.application_gateway_name

  # Tags
  tags = var.tags
}

# ============================================================================
# Kubernetes and Helm providers
# Uses module outputs directly from the cluster resource (per Azure provider docs)
# ============================================================================

provider "kubernetes" {
  host                   = module.crewai_platform.kubernetes_host
  cluster_ca_certificate = base64decode(module.crewai_platform.kubernetes_cluster_ca_certificate)
  client_certificate     = base64decode(module.crewai_platform.kubernetes_client_certificate)
  client_key             = base64decode(module.crewai_platform.kubernetes_client_key)
}

provider "helm" {
  kubernetes {
    host                   = module.crewai_platform.kubernetes_host
    cluster_ca_certificate = base64decode(module.crewai_platform.kubernetes_cluster_ca_certificate)
    client_certificate     = base64decode(module.crewai_platform.kubernetes_client_certificate)
    client_key             = base64decode(module.crewai_platform.kubernetes_client_key)
  }
}

# ============================================================================
# CrewAI Cluster Add-ons Module
# Installs AGIC and creates database Kubernetes secret
# ============================================================================

module "crewai_cluster_addons" {
  source = "../../modules/azure/cluster-addons"

  resource_group_name = module.crewai_platform.resource_group_name
  location            = module.crewai_platform.resource_group_location

  # Cluster configuration
  cluster_name    = module.crewai_platform.cluster_configuration.cluster_name
  oidc_issuer_url = module.crewai_platform.cluster_configuration.oidc_issuer_url

  # Application Gateway configuration (from networking module)
  application_gateway_id   = module.crewai_platform.network_configuration.application_gateway_id
  application_gateway_name = module.crewai_platform.network_configuration.application_gateway_name

  # Network configuration
  vnet_id         = module.crewai_platform.network_configuration.vnet_id
  subscription_id = data.azurerm_client_config.current.subscription_id

  # Database connection
  db_host     = module.crewai_platform.database_configuration.server_fqdn
  db_port     = 5432
  db_name     = module.crewai_platform.database_configuration.database_name
  db_username = module.crewai_platform.database_configuration.administrator_login
  db_password = module.crewai_platform.db_password

  # Optional overrides
  platform_namespace = var.platform_namespace

  # Ensure cluster exists before attempting to install add-ons
  depends_on = [module.crewai_platform]
}
