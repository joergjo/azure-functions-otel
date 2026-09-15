resource "azurerm_managed_redis" "this" {
  name                      = "redis-${var.resource_token}"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  sku_name                  = "Balanced_B0"
  high_availability_enabled = false
  public_network_access     = "Enabled"

  default_database {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
    clustering_policy                  = "OSSCluster"
    eviction_policy                    = "VolatileLRU"
  }

  tags = var.tags
}
