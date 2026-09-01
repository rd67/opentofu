# Azure Cache for Redis, PUBLIC ACCESS mode (same tradeoff as MySQL - see
# azure/README.md). Non-SSL port is disabled, so the only reachable port is
# the SSL port (ssl_port output / 6380 by default).
resource "azurerm_redis_cache" "main" {
  name                 = "${local.name_prefix}-redis"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  capacity             = var.redis_capacity
  family               = var.redis_family
  sku_name             = var.redis_sku_name
  non_ssl_port_enabled = false
  minimum_tls_version  = "1.2"

  redis_configuration {}

  tags = local.tags
}

# One rule per app VM's public IP, mirroring the MySQL firewall rules.
resource "azurerm_redis_firewall_rule" "app_vms" {
  for_each = local.apps

  name                = "allow_${each.key}_vm"
  redis_cache_name    = azurerm_redis_cache.main.name
  resource_group_name = azurerm_resource_group.main.name
  start_ip            = azurerm_public_ip.app[each.key].ip_address
  end_ip              = azurerm_public_ip.app[each.key].ip_address
}
