variable "resource_group_name" {
  description = "Name of the resource group that contains Azure Managed Redis."
  type        = string
}

variable "location" {
  description = "Azure region for Azure Managed Redis."
  type        = string
}

variable "resource_token" {
  description = "Unique token used to generate resource names."
  type        = string
}

variable "tags" {
  description = "Tags to apply to Azure Managed Redis."
  type        = map(string)
  default     = {}
}
