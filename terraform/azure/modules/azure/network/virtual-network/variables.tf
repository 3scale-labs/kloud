variable "resource_group" {
  description = "Azure Resource Group"
}

variable "name" {
  description = "Virtual Network name"
  type        = "string"
}

variable "address_space" {
  description = "Network Address Space"
  type        = "list"
  default     = ["10.0.0.0/8"]
}

variable "compute_subnet" {
  description = "Subnet a CIDR"
  type        = "string"
  default     = "10.1.0.0/16"
}
