variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "key_vault_name" {
  description = "Base name for the Key Vault"
  type        = string
}

variable "resource_suffix" {
  description = "Suffix to append for globally unique names (provided by parent module)"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "vnet_id" {
  description = "ID of the virtual network for private endpoint"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for private endpoint"
  type        = string
}

variable "authorized_ip_ranges" {
  description = "List of authorized IP addresses for Key Vault access (CIDR notation)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
