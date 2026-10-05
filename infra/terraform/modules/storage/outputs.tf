output "storage_account_id" {
  description = "Resource ID of the collector configuration storage account."
  value       = azurerm_storage_account.collector_config.id
}

output "storage_account_name" {
  description = "Name of the collector configuration storage account."
  value       = azurerm_storage_account.collector_config.name
}

output "collector_config_url" {
  description = "Public URL of the deployed OpenTelemetry Collector configuration."
  value       = azurerm_storage_blob.collector_config.url
}

output "collector_config_content_md5" {
  description = "MD5 hash of the deployed OpenTelemetry Collector configuration content."
  value       = azurerm_storage_blob.collector_config.content_md5
}
