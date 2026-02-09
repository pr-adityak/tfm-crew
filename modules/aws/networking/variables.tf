# Networking Module Variables

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "crewai-"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16" # Provides plenty of IP space
}

variable "az_count" {
  description = "Number of availability zones to use (minimum 2 for HA)"
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "public_subnet_newbits" {
  description = "Number of bits to add to VPC CIDR for public subnets (e.g., 8 makes /24 from /16)"
  type        = number
  default     = 8 # Creates /24 subnets from /16 VPC (256 IPs each, well above 8 minimum)
}

variable "private_subnet_newbits" {
  description = "Number of bits to add to VPC CIDR for private subnets"
  type        = number
  default     = 4 # Creates /20 subnets from /16 VPC (4096 IPs each, recommended for compute workloads)
}

variable "region" {
  description = "AWS region"
  type        = string
}

# ========================================
# EXISTING VPC CONFIGURATION
# Use when deploying into an existing VPC instead of creating a new one
# ========================================

variable "use_existing_vpc" {
  description = "Use an existing VPC instead of creating a new one"
  type        = bool
  default     = false

  validation {
    condition     = !var.use_existing_vpc || (var.existing_vpc_id != "" && length(var.existing_private_subnet_ids) >= 2)
    error_message = "When use_existing_vpc is true, existing_vpc_id and at least 2 existing_private_subnet_ids are required."
  }
}

variable "existing_vpc_id" {
  description = "ID of existing VPC (required when use_existing_vpc = true)"
  type        = string
  default     = ""
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs (required when use_existing_vpc = true, minimum 2 in different AZs)"
  type        = list(string)
  default     = []
}

variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs (optional, for internet-facing ALBs)"
  type        = list(string)
  default     = []
}

variable "create_vpc_endpoints" {
  description = "Create VPC endpoints when using existing VPC (Secrets Manager, CloudWatch Logs, S3). Set to false if endpoints already exist."
  type        = bool
  default     = true
}
