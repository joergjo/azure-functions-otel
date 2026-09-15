output "function_app_name" {
  description = "Name of the Flex Consumption Function App."
  value       = azurerm_function_app_flex_consumption.this.name
}

output "function_app_endpoint" {
  description = "Default hostname of the Flex Consumption Function App."
  value       = azurerm_function_app_flex_consumption.this.default_hostname
}

output "service_plan_id" {
  description = "Resource ID of the FC1 service plan."
  value       = azurerm_service_plan.functions.id
}

output "storage_account_name" {
  description = "Name of the Function App runtime storage account."
  value       = azurerm_storage_account.runtime.name
}

output "user_assigned_identity_id" {
  description = "Resource ID of the Function App user-assigned identity."
  value       = azurerm_user_assigned_identity.data_owner.id
}
