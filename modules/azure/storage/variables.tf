variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "data_storage_account_name" {
  description = "Base name for data storage account"
  type        = string
}

variable "logs_storage_account_name" {
  description = "Base name for logs storage account"
  type        = string
}

variable "resource_suffix" {
  description = "Suffix to append for globally unique names (provided by parent module)"
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
