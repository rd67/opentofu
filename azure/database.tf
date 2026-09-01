# Azure Database for MySQL Flexible Server, PUBLIC ACCESS mode.
#
# This is a deliberate starter-simplicity tradeoff: no delegated_subnet_id /
# private_dns_zone_id (which would require VNet integration), just a public
# endpoint gated by IP-allowlist firewall rules. See azure/README.md for
# what to change for a production deployment (private endpoint / VNet
# integration instead).
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "${local.name_prefix}-mysql"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password
  sku_name               = var.mysql_sku_name
  version                = "8.0.21"

  # Explicit even though "Enabled" is the default for non-VNet-integrated
  # servers - makes the public-endpoint choice visible in the code.
  public_network_access = "Enabled"

  tags = local.tags
}

resource "azurerm_mysql_flexible_database" "app" {
  # MySQL flexible database names can't contain dashes.
  name                = replace("${var.project_name}_${var.environment}_app", "-", "_")
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Required so the server is reachable at all from Azure-hosted resources
# (documented Azure mechanism: a rule with start/end IP both 0.0.0.0).
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  name                = "allow_azure_services"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# One rule per app VM's public IP, so only the three VMs deployed by this
# module (rather than an arbitrary user-supplied CIDR) can reach MySQL.
resource "azurerm_mysql_flexible_server_firewall_rule" "app_vms" {
  for_each = local.apps

  name                = "allow_${each.key}_vm"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = azurerm_public_ip.app[each.key].ip_address
  end_ip_address      = azurerm_public_ip.app[each.key].ip_address
}
