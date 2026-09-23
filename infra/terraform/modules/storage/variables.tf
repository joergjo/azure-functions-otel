variable "resource_group_name" {
  description = "Name of the resource group that contains the collector configuration storage account."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region for the storage resources."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "resource_token" {
  description = "Lowercase alphanumeric token appended to the stconfig storage account prefix."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,16}$", var.resource_token))
    error_message = "resource_token must contain 3-16 lowercase letters or digits so the storage account name remains valid."
  }
}

variable "log_analytics_workspace_resource_id" {
  description = "Resource ID of the Log Analytics workspace receiving Blob service diagnostics."
  type        = string
}

variable "collector_config_source_path" {
  description = "Optional path to collector.deployed.yaml. Set exactly one of this variable or collector_config_content."
  type        = string
  default     = null

  validation {
    condition     = (var.collector_config_source_path != null) != (var.collector_config_content != null)
    error_message = "Set exactly one of collector_config_source_path or collector_config_content."
  }
}

variable "collector_config_content" {
  description = "Optional inline contents of collector.deployed.yaml. Set exactly one of this variable or collector_config_source_path."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the storage account."
  type        = map(string)
  default     = {}
}
