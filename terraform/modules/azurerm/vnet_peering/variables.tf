variable "name" {
  description = "Name of the virtual network peering"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the source virtual network"
  type        = string
}

variable "remote_virtual_network_id" {
  description = "ID of the remote virtual network"
  type        = string
}

variable "allow_virtual_network_access" {
  description = "Allow access to the remote virtual network"
  type        = bool
  default     = true
}

variable "allow_forwarded_traffic" {
  description = "Allow forwarded traffic from the remote virtual network"
  type        = bool
  default     = true
}

variable "allow_gateway_transit" {
  description = "Allow gateway transit"
  type        = bool
  default     = false
}

variable "use_remote_gateways" {
  description = "Use remote gateways"
  type        = bool
  default     = false
}
