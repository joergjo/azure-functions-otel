locals {
  app_name                          = "func-${var.resource_token}"
  deployment_storage_container_name = "app-package-${substr(local.app_name, 0, 32)}-${substr(var.resource_token, 0, 7)}"
}

resource "azurerm_storage_account" "runtime" {
  name                = "st${var.resource_token}"
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  access_tier                     = "Hot"
  allow_nested_items_to_be_public = false
  dns_endpoint_type               = "Standard"
  shared_access_key_enabled       = false
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true

  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Allow"
  }

  tags = var.tags
}

resource "azurerm_storage_container" "app_package" {
  name                  = local.deployment_storage_container_name
  storage_account_id    = azurerm_storage_account.runtime.id
  container_access_type = "private"
}

resource "azurerm_monitor_diagnostic_setting" "runtime_blob_reads" {
  name                       = "blob-read-logs"
  target_resource_id         = "${azurerm_storage_account.runtime.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_resource_id

  enabled_log {
    category = "StorageRead"
  }
}

resource "azurerm_user_assigned_identity" "data_owner" {
  name                = "uai-data-owner-${var.resource_token}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "storage_blob_data_owner" {
  scope                = azurerm_storage_account.runtime.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.data_owner.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  scope                = azurerm_storage_account.runtime.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.data_owner.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "storage_queue_data_contributor" {
  scope                = azurerm_storage_account.runtime.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_user_assigned_identity.data_owner.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "storage_table_data_contributor" {
  scope                = azurerm_storage_account.runtime.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.data_owner.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "monitoring_metrics_publisher" {
  scope                = var.application_insights_resource_id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.data_owner.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_service_plan" "functions" {
  name                = "plan-${var.resource_token}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = var.tags
}

resource "azurerm_function_app_flex_consumption" "this" {
  name                = local.app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.functions.id

  storage_container_type            = "blobContainer"
  storage_container_endpoint        = azurerm_storage_container.app_package.url
  storage_authentication_type       = "UserAssignedIdentity"
  storage_user_assigned_identity_id = azurerm_user_assigned_identity.data_owner.id
  runtime_name                      = var.function_app_runtime
  runtime_version                   = var.function_app_runtime_version
  maximum_instance_count            = var.maximum_instance_count
  instance_memory_in_mb             = var.instance_memory_mb
  https_only                        = true

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.data_owner.id]
  }

  site_config {
    minimum_tls_version = "1.2"
  }

  app_settings = merge(
    {
      AzureWebJobsStorage__accountName                  = azurerm_storage_account.runtime.name
      AzureWebJobsStorage__credential                   = "managedidentity"
      AzureWebJobsStorage__clientId                     = azurerm_user_assigned_identity.data_owner.client_id
      APPINSIGHTS_INSTRUMENTATIONKEY                    = var.application_insights_instrumentation_key
      APPLICATIONINSIGHTS_AUTHENTICATION_STRING         = "ClientId=${azurerm_user_assigned_identity.data_owner.client_id};Authorization=AAD"
      EventHubConnectionString                          = var.event_hub_primary_connection_string
      EventHubName                                      = var.event_hub_name
      ConsumerGroup                                     = var.consumer_group
      OTEL_EXPORTER_OTLP_ENDPOINT                       = var.otel_collector_https_endpoint
      OTEL_SERVICE_NAME                                 = "demo-function-app"
      OTEL_RESOURCE_ATTRIBUTES                          = "service.version=0.1.0"
      OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE = "temporality"
      RedisConnectionString                             = "rediss://${var.redis_hostname}:${var.redis_port}"
      RedisPassword                                     = var.redis_primary_access_key
    },
    var.otel_traces_sampler == "" ? {} : { OTEL_TRACES_SAMPLER = var.otel_traces_sampler },
    var.otel_traces_sampler_arg == "" ? {} : { OTEL_TRACES_SAMPLER_ARG = var.otel_traces_sampler_arg },
  )

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.storage_blob_data_owner,
    azurerm_role_assignment.storage_blob_data_contributor,
    azurerm_role_assignment.storage_queue_data_contributor,
    azurerm_role_assignment.storage_table_data_contributor,
    azurerm_role_assignment.monitoring_metrics_publisher,
  ]
}
