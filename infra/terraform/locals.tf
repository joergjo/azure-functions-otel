locals {
  resource_token = coalesce(
    var.resource_token,
    substr(md5("${data.azurerm_client_config.current.subscription_id}:${var.resource_group_name}:${var.location}"), 0, 13)
  )

  tags = {
    SecurityControl = "Ignore"
  }
}
