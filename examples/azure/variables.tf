variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region (e.g., eastus, westus2)"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "crewai-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "crewai-aks"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "authorized_ip_ranges" {
  description = "Authorized IP ranges for AKS API server access (CIDR notation). Terraform runner IP is automatically added."
  type        = list(string)
  default     = []
}

variable "db_server_name" {
  description = "Name of the PostgreSQL server"
  type        = string
}

variable "db_administrator_login" {
  description = "Database administrator login"
  type        = string
  default     = "crewai_admin"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "crewai"
}

variable "db_reader_instance_count" {
  description = "Number of database read replicas"
  type        = number
  default     = 1
}

variable "data_storage_account_name" {
  description = "Base name for data storage account (must be globally unique, lowercase alphanumeric, 3-24 chars)"
  type        = string
}

variable "logs_storage_account_name" {
  description = "Base name for logs storage account (must be globally unique, lowercase alphanumeric, 3-24 chars)"
  type        = string
}

variable "acr_name" {
  description = "Base name for Azure Container Registry (must be globally unique, alphanumeric, 5-50 chars)"
  type        = string
  default     = "crewai"
}

variable "key_vault_name" {
  description = "Base name for Key Vault (must be globally unique, alphanumeric and hyphens, 3-24 chars)"
  type        = string
  default     = "crewai-kv"
}

variable "application_gateway_name" {
  description = "Name for Application Gateway"
  type        = string
  default     = "crewai-appgw"
}

variable "platform_namespace" {
  description = "Kubernetes namespace for platform components"
  type        = string
  default     = "platform"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "CrewAI"
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}
