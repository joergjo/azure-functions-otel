variable "resource_group_name" {
  description = "Name of the resource group that contains the Function App."
  type        = string
}

variable "location" {
  description = "Azure region for the Function App resources."
  type        = string
}

variable "resource_token" {
  description = "Unique token used to generate resource names."
  type        = string
}

variable "function_app_runtime" {
  description = "Language runtime used by the Function App."
  type        = string
  default     = "node"
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
}

variable "instance_memory_mb" {
  description = "Memory allocated to each Function App instance."
  type        = number
  default     = 2048
}

variable "application_insights_resource_id" {
  description = "Resource ID of the Application Insights component."
  type        = string
}

variable "log_analytics_workspace_resource_id" {
  description = "Resource ID of the Log Analytics workspace receiving Blob service diagnostics."
  type        = string
}

variable "application_insights_instrumentation_key" {
  description = "Instrumentation key produced by the Application Insights module."
  type        = string
  sensitive   = true
}

variable "event_hub_name" {
  description = "Name of the Event Hub consumed by the Function App."
  type        = string
}

variable "event_hub_primary_connection_string" {
  description = "Namespace-scoped Event Hubs primary connection string without EntityPath."
  type        = string
  sensitive   = true
}

variable "consumer_group" {
  description = "Consumer group used by the Event Hub trigger."
  type        = string
  default     = "$Default"
}

variable "otel_collector_https_endpoint" {
  description = "HTTPS endpoint of the OpenTelemetry Collector."
  type        = string

  validation {
    condition     = startswith(var.otel_collector_https_endpoint, "https://")
    error_message = "otel_collector_https_endpoint must begin with https://."
  }
}

variable "redis_hostname" {
  description = "DNS hostname produced by the Azure Managed Redis module."
  type        = string
}

variable "redis_port" {
  description = "TLS port produced by the Azure Managed Redis module."
  type        = number
}

variable "redis_primary_access_key" {
  description = "Primary access key produced by the Azure Managed Redis module."
  type        = string
  sensitive   = true
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

variable "tags" {
  description = "Tags to apply to Function App resources."
  type        = map(string)
  default     = {}
}
