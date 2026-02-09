variable "resource_group_name" {
  description = "Name of the resource group (will be created if it doesn't exist)"
  type        = string
}

variable "location" {
  description = "Azure region"
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
  description = "Authorized IP ranges for AKS API server access and Key Vault network access (CIDR notation)"
  type        = list(string)
  default     = []
}

variable "db_server_name" {
  description = "Name of the PostgreSQL server"
  type        = string
  default     = "crewai-postgres"
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
  description = "Base name for data storage account"
  type        = string
  default     = "crewaidata"
}

variable "logs_storage_account_name" {
  description = "Base name for logs storage account"
  type        = string
  default     = "crewailogs"
}

variable "acr_name" {
  description = "Base name for Azure Container Registry"
  type        = string
  default     = "crewai"
}

variable "key_vault_name" {
  description = "Base name for Key Vault"
  type        = string
  default     = "crewai-kv"
}

variable "application_gateway_name" {
  description = "Name for Application Gateway"
  type        = string
  default     = "crewai-appgw"
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
