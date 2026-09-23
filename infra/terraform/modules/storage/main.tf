locals {
  collector_config_content = var.collector_config_content != null ? var.collector_config_content : file(var.collector_config_source_path)
}

resource "azurerm_storage_account" "collector_config" {
  name                            = "stconfig${var.resource_token}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  access_tier                     = "Hot"
  allow_nested_items_to_be_public = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  tags                            = var.tags
}

resource "azurerm_storage_container" "config" {
  name                  = "config"
  storage_account_id    = azurerm_storage_account.collector_config.id
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "collector_config" {
  name                 = "collector.deployed.yaml"
  storage_container_id = azurerm_storage_container.config.id
  type                 = "Block"
  source_content       = local.collector_config_content
  content_md5          = md5(local.collector_config_content)
  content_type         = "application/yaml"
}

resource "azurerm_monitor_diagnostic_setting" "collector_config_blob_reads" {
  name                       = "blob-read-logs"
  target_resource_id         = "${azurerm_storage_account.collector_config.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_resource_id

  enabled_log {
    category = "StorageRead"
  }
}
