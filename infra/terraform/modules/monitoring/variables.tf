variable "resource_group_name" {
  description = "Name of the resource group that contains the monitoring resources."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Primary Azure region for the monitoring resources."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "resource_token" {
  description = "Unique token used for resource name generation."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,20}$", var.resource_token))
    error_message = "resource_token must contain 3-20 lowercase letters or digits."
  }
}

variable "collector_principal_id" {
  description = "Object ID of the OpenTelemetry Collector service principal."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.collector_principal_id))
    error_message = "collector_principal_id must be a valid UUID."
  }
}
