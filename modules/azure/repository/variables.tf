variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "registry_name" {
  description = "Base name for container registry"
  type        = string
}

variable "resource_suffix" {
  description = "Suffix to append for globally unique names (provided by parent module)"
  type        = string
}

variable "sku" {
  description = "SKU for the container registry (Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
