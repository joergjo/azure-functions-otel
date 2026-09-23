resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  resource_token         = local.resource_token
  collector_principal_id = var.collector_principal_id
}

module "eventhubs" {
  source = "./modules/eventhubs"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  resource_token      = local.resource_token
  sku                 = var.event_hub_sku
  tags                = local.tags
}

module "redis" {
  source = "./modules/redis"

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  resource_token      = local.resource_token
  tags                = local.tags
}

module "storage" {
  source = "./modules/storage"

  resource_group_name                 = azurerm_resource_group.this.name
  location                            = azurerm_resource_group.this.location
  resource_token                      = local.resource_token
  log_analytics_workspace_resource_id = module.monitoring.log_analytics_workspace_resource_id
  collector_config_content            = file("${path.root}/../../config/collector.deployed.yaml")
  tags                                = local.tags
}

module "appservice" {
  source = "./modules/appservice"

  resource_group_name  = azurerm_resource_group.this.name
  location             = azurerm_resource_group.this.location
  resource_token       = local.resource_token
  app_service_sku      = var.app_service_sku
  app_service_tier     = var.app_service_tier
  collector_image_tag  = var.collector_image_tag
  client_id            = var.client_id
  client_secret        = var.client_secret
  tenant_id            = var.tenant_id
  logs_endpoint        = module.monitoring.log_ingestion_endpoint
  traces_endpoint      = module.monitoring.trace_ingestion_endpoint
  metrics_endpoint     = module.monitoring.metrics_ingestion_endpoint
  collector_config_url = module.storage.collector_config_url
  tags                 = local.tags
}

module "functions" {
  source = "./modules/functions"

  resource_group_name                      = azurerm_resource_group.this.name
  location                                 = azurerm_resource_group.this.location
  resource_token                           = local.resource_token
  function_app_runtime                     = var.function_app_runtime
  function_app_runtime_version             = var.function_app_runtime_version
  maximum_instance_count                   = var.maximum_instance_count
  instance_memory_mb                       = var.instance_memory_mb
  application_insights_resource_id         = module.monitoring.application_insights_resource_id
  log_analytics_workspace_resource_id      = module.monitoring.log_analytics_workspace_resource_id
  application_insights_instrumentation_key = module.monitoring.application_insights_instrumentation_key
  event_hub_name                           = module.eventhubs.hub_name
  event_hub_primary_connection_string      = module.eventhubs.primary_connection_string
  otel_collector_https_endpoint            = module.appservice.app_service_url
  redis_hostname                           = module.redis.hostname
  redis_port                               = module.redis.port
  redis_primary_access_key                 = module.redis.primary_access_key
  otel_traces_sampler                      = var.otel_traces_sampler
  otel_traces_sampler_arg                  = var.otel_traces_sampler_arg
  tags                                     = local.tags
}
