variable "location" {
  description = "The location/region where the resources will be created"
  default     = "East US"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "network_config" {
  description = "Configuration for the virtual network"
  type = object({
    address_space = list(string)
    subnet_prefixes = list(string)
    subnet_names = list(string)
  })
  default = {
    address_space   = ["10.0.0.0/16"]
    subnet_prefixes = ["10.0.1.0/24"]
    subnet_names    = ["default"]
  }
}
