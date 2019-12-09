variable "resource_group" {
  description = "Azure Resource Group"
}

variable "name" {
  description = "Virtual Machine name"
  type        = "string"
}

variable "vm_size" {
  description = "VM size"
  type        = "string"
  default     = "Standard_B2s"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  default     = "1.14.7"
}
