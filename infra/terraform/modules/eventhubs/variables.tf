variable "resource_group_name" {
  description = "Name of the resource group that contains the Event Hubs resources."
  type        = string
}

variable "location" {
  description = "Azure region for the Event Hubs resources."
  type        = string
}

variable "resource_token" {
  description = "Unique token used to generate resource names."
  type        = string
}

variable "sku" {
  description = "Messaging tier for the Event Hubs namespace."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be Basic or Standard."
  }
}

variable "tags" {
  description = "Tags to apply to the Event Hubs namespace."
  type        = map(string)
  default     = {}
}
