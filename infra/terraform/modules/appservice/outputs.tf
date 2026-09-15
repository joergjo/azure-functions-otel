output "service_plan_id" {
  description = "Resource ID of the collector App Service plan."
  value       = azurerm_service_plan.collector.id
}

output "app_service_id" {
  description = "Resource ID of the collector Linux Web App."
  value       = azurerm_linux_web_app.collector.id
}

output "app_service_endpoint" {
  description = "Default hostname of the collector Linux Web App."
  value       = azurerm_linux_web_app.collector.default_hostname
}

output "app_service_url" {
  description = "HTTPS URL of the collector Linux Web App."
  value       = "https://${azurerm_linux_web_app.collector.default_hostname}"
}
