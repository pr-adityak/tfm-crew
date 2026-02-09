variable "resource_group_name" {
  description = "Name of the resource group"
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

variable "aks_subnet_address_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.0.0/23"
}

variable "appgw_subnet_address_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "postgres_subnet_address_prefix" {
  description = "Address prefix for PostgreSQL delegated subnet"
  type        = string
  default     = "10.0.5.0/24"
}

variable "application_gateway_name" {
  description = "Name of the Application Gateway"
  type        = string
  default     = "crewai-appgw"
}

variable "appgw_sku_name" {
  description = "SKU name for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "appgw_sku_tier" {
  description = "SKU tier for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "appgw_min_capacity" {
  description = "Minimum autoscale capacity for Application Gateway"
  type        = number
  default     = 0
}

variable "appgw_max_capacity" {
  description = "Maximum autoscale capacity for Application Gateway"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
