resource "azurerm_service_plan" "collector" {
  name                = "asp-${var.resource_token}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  worker_count        = 1
  tags                = var.tags

  lifecycle {
    precondition {
      condition     = var.app_service_tier == "PremiumV4"
      error_message = "app_service_tier must be PremiumV4; AzureRM derives the tier from the P*v4 sku_name."
    }
  }
}

resource "azurerm_linux_web_app" "collector" {
  name                = "app-${var.resource_token}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.collector.id
  https_only          = true
  tags                = var.tags

  app_settings = {
    WEBSITES_PORT    = "4318"
    HTTP20_ONLY_PORT = "4317"
    CLIENT_ID        = var.client_id
    CLIENT_SECRET    = var.client_secret
    TENANT_ID        = var.tenant_id
    LOGS_ENDPOINT    = var.logs_endpoint
    TRACES_ENDPOINT  = var.traces_endpoint
    METRICS_ENDPOINT = var.metrics_endpoint
  }

  site_config {
    app_command_line = "--config=${var.collector_config_url}"
    http2_enabled    = true

    application_stack {
      docker_image_name   = "otel/opentelemetry-collector-contrib:latest"
      docker_registry_url = "https://index.docker.io"
    }
  }
}

resource "azapi_update_resource" "http2_proxy" {
  type        = "Microsoft.Web/sites/config@2025-03-01"
  resource_id = "${azurerm_linux_web_app.collector.id}/config/web"

  body = {
    properties = {
      http20ProxyFlag = 2
    }
  }

  response_export_values = {
    http20_proxy_flag = "properties.http20ProxyFlag"
  }

  lifecycle {
    postcondition {
      condition     = self.output.http20_proxy_flag == 2
      error_message = "The collector App Service web configuration did not persist http20ProxyFlag=2."
    }
  }
}
