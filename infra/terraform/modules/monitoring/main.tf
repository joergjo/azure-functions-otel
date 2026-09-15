data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.resource_token}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_workspace" "this" {
  name                          = "ws-${var.resource_token}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = true
}

resource "azapi_resource" "application_insights" {
  type                      = "Microsoft.Insights/components@2020-02-02"
  name                      = "appi-${var.resource_token}"
  parent_id                 = data.azurerm_resource_group.this.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    kind = "web"
    properties = {
      Application_Type                   = "web"
      DisableLocalAuth                   = true
      WorkspaceResourceId                = azurerm_log_analytics_workspace.this.id
      AzureMonitorWorkspaceResourceId    = azurerm_monitor_workspace.this.id
      AzureMonitorWorkspaceIngestionMode = "Enabled"
    }
  }
}

data "azapi_resource" "application_insights" {
  type        = "Microsoft.Insights/components@2020-02-02"
  resource_id = azapi_resource.application_insights.id

  response_export_values = {
    data_collection_rule_resource_id = "properties.DataCollectionRuleResourceId"
    instrumentation_key              = "properties.InstrumentationKey"
    log_ingestion_endpoint           = "properties.OTLPLogsEndpoint"
    metrics_ingestion_endpoint       = "properties.OTLPMetricsEndpoint"
    trace_ingestion_endpoint         = "properties.OTLPTracesEndpoint"
  }

  depends_on = [azapi_resource.application_insights]
}

resource "azapi_resource" "monitoring_metrics_publisher" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", "${data.azapi_resource.application_insights.output.data_collection_rule_resource_id}:${var.collector_principal_id}:Monitoring Metrics Publisher")
  parent_id = data.azapi_resource.application_insights.output.data_collection_rule_resource_id

  body = {
    properties = {
      roleDefinitionId = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb"
      principalId      = var.collector_principal_id
      principalType    = "ServicePrincipal"
    }
  }

  retry = {
    error_message_regex  = ["ResourceNotFound", "ParentResourceNotFound"]
    interval_seconds     = 5
    max_interval_seconds = 30
  }
}
