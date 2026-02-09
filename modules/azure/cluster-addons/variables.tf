variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "application_gateway_id" {
  description = "ID of the Application Gateway"
  type        = string
}

variable "application_gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "db_host" {
  description = "Database host (FQDN)"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "platform_namespace" {
  description = "Kubernetes namespace for platform components"
  type        = string
  default     = "platform"
}

variable "database_secret_name" {
  description = "Name of the Kubernetes secret for database credentials"
  type        = string
  default     = "database-credentials"
}

variable "agic_helm_version" {
  description = "Version of the AGIC Helm chart"
  type        = string
  default     = "1.7.5"
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL from AKS cluster for workload identity"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
