variable "resource_group_name" {
  description = "Name of the resource group that contains the collector App Service."
  type        = string

  validation {
    condition     = length(trimspace(var.resource_group_name)) > 0
    error_message = "resource_group_name must not be empty."
  }
}

variable "location" {
  description = "Azure region for the App Service resources."
  type        = string

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "resource_token" {
  description = "Lowercase alphanumeric token used to generate globally unique App Service names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,20}$", var.resource_token))
    error_message = "resource_token must contain 3-20 lowercase letters or digits."
  }
}

variable "app_service_sku" {
  description = "Premium v4 SKU for the Linux App Service plan."
  type        = string
  default     = "P0v4"

  validation {
    condition     = can(regex("^P([0-3]|[1-5]m)v4$", var.app_service_sku))
    error_message = "app_service_sku must be a Premium v4 SKU such as P0v4."
  }
}

variable "app_service_tier" {
  description = "Expected App Service plan tier; AzureRM derives this value from app_service_sku."
  type        = string
  default     = "PremiumV4"
}

variable "collector_image_tag" {
  description = "Tag and optional digest for the OpenTelemetry Collector Contrib container image."
  type        = string

  validation {
    condition     = length(trimspace(var.collector_image_tag)) > 0
    error_message = "collector_image_tag must not be empty."
  }
}

variable "logs_endpoint" {
  description = "Azure Monitor logs ingestion endpoint."
  type        = string
}

variable "traces_endpoint" {
  description = "Azure Monitor traces ingestion endpoint."
  type        = string
}

variable "metrics_endpoint" {
  description = "Azure Monitor metrics ingestion endpoint."
  type        = string
}

variable "collector_config_url" {
  description = "Absolute public URL of the OpenTelemetry Collector configuration."
  type        = string

  validation {
    condition     = can(regex("^https://", var.collector_config_url))
    error_message = "collector_config_url must be an HTTPS URL."
  }
}

variable "collector_config_content_md5" {
  description = "MD5 hash of the OpenTelemetry Collector configuration, used only to force an App Service restart when the config content changes."
  type        = string
}

variable "data_collection_rule_resource_id" {
  description = "Resource ID of the Data Collection Rule that receives OpenTelemetry Collector telemetry."
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft\\.Insights/dataCollectionRules/.+$", var.data_collection_rule_resource_id))
    error_message = "data_collection_rule_resource_id must be a valid Data Collection Rule resource ID."
  }
}

variable "tags" {
  description = "Tags to apply to the App Service plan and web app."
  type        = map(string)
  default     = {}
}
