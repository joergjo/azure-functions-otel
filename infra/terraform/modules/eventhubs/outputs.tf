output "namespace_name" {
  description = "Name of the Event Hubs namespace."
  value       = azurerm_eventhub_namespace.this.name
}

output "namespace_id" {
  description = "Resource ID of the Event Hubs namespace."
  value       = azurerm_eventhub_namespace.this.id
}

output "hub_name" {
  description = "Name of the Event Hub."
  value       = azurerm_eventhub.test.name
}

output "service_bus_endpoint" {
  description = "Service Bus endpoint for the Event Hubs namespace."
  value       = "sb://${azurerm_eventhub_namespace.this.name}.servicebus.windows.net/"
}

output "primary_connection_string" {
  description = "Namespace-scoped RootManageSharedAccessKey primary connection string. It does not include EntityPath."
  value       = azurerm_eventhub_namespace.this.default_primary_connection_string
  sensitive   = true
}
