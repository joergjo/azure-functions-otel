variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
}

variable "location" {
  description = "Primary Azure region for all resources."
  type        = string
  default     = "swedencentral"
}

variable "resource_token" {
  description = "Optional token used for resource name generation."
  type        = string
  default     = null

  validation {
    condition     = var.resource_token == null || can(regex("^[a-z0-9]{3,16}$", var.resource_token))
    error_message = "resource_token must contain 3-16 lowercase letters or digits."
  }
}

variable "function_app_runtime" {
  description = "Language runtime used by the Function App."
  type        = string
  default     = "node"

  validation {
    condition     = contains(["dotnet-isolated", "python", "java", "node", "powershell"], var.function_app_runtime)
    error_message = "function_app_runtime must be dotnet-isolated, python, java, node, or powershell."
  }
}

variable "function_app_runtime_version" {
  description = "Target language version used by the Function App."
  type        = string
  default     = "24"
}

variable "maximum_instance_count" {
  description = "Maximum Function App scale-out instance count."
  type        = number
  default     = 100

  validation {
    condition     = var.maximum_instance_count >= 40 && var.maximum_instance_count <= 1000
    error_message = "maximum_instance_count must be between 40 and 1000."
  }
}

variable "instance_memory_mb" {
  description = "Memory allocated to each Function App instance."
  type        = number
  default     = 2048

  validation {
    condition     = contains([2048, 4096], var.instance_memory_mb)
    error_message = "instance_memory_mb must be 2048 or 4096."
  }
}

variable "event_hub_sku" {
  description = "Event Hubs namespace SKU."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.event_hub_sku)
    error_message = "event_hub_sku must be Basic or Standard."
  }
}

variable "app_service_sku" {
  description = "SKU for the collector App Service plan."
  type        = string
  default     = "P0v4"
}

variable "app_service_tier" {
  description = "Tier for the collector App Service plan."
  type        = string
  default     = "PremiumV4"
}

variable "collector_image_tag" {
  description = "Tag and optional digest for the OpenTelemetry Collector Contrib container image."
  type        = string
  default     = "0.161.0@sha256:fd328de2552466ad78385e1b1289c3f2402b1c45f265b252aab1955b42845ac1"

  validation {
    condition     = length(trimspace(var.collector_image_tag)) > 0
    error_message = "collector_image_tag must not be empty."
  }
}

variable "client_id" {
  description = "Client ID used by the OpenTelemetry Collector."
  type        = string
}

variable "client_secret" {
  description = "Client secret used by the OpenTelemetry Collector."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Tenant ID used by the OpenTelemetry Collector."
  type        = string
}

variable "collector_principal_id" {
  description = "Object ID of the OpenTelemetry Collector service principal."
  type        = string
}

variable "otel_traces_sampler" {
  description = "Value for the Function App's OTEL_TRACES_SAMPLER setting. Left unset when empty."
  type        = string
  default     = ""
}

variable "otel_traces_sampler_arg" {
  description = "Value for the Function App's OTEL_TRACES_SAMPLER_ARG setting. Left unset when empty."
  type        = string
  default     = ""
}
