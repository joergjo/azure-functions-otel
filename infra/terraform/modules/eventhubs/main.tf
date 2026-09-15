resource "azurerm_eventhub_namespace" "this" {
  name                = "ehns-${var.resource_token}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  capacity            = 1

  auto_inflate_enabled          = false
  local_authentication_enabled  = true
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  tags = var.tags
}

resource "azurerm_eventhub" "test" {
  name              = "test"
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = 4
  message_retention = var.sku == "Basic" ? 1 : 7
}
