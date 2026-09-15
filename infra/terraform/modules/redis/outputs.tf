output "name" {
  description = "Name of the Azure Managed Redis instance."
  value       = azurerm_managed_redis.this.name
}

output "id" {
  description = "Resource ID of the Azure Managed Redis instance."
  value       = azurerm_managed_redis.this.id
}

output "hostname" {
  description = "DNS hostname of the Azure Managed Redis endpoint."
  value       = azurerm_managed_redis.this.hostname
}

output "port" {
  description = "TLS port of the default Redis database."
  value       = azurerm_managed_redis.this.default_database[0].port
}

output "primary_access_key" {
  description = "Primary access key of the default Redis database."
  value       = azurerm_managed_redis.this.default_database[0].primary_access_key
  sensitive   = true
}
