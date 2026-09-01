output "lb_url" {
  description = "Application Gateway URL - path-routes to all three apps"
  value       = "http://${azurerm_public_ip.appgw.ip_address}"
}

output "node_app_url" {
  description = "Node.js status app URL (via the Application Gateway)"
  value       = "http://${azurerm_public_ip.appgw.ip_address}/nodejs"
}

output "python_app_url" {
  description = "Python status app URL (via the Application Gateway)"
  value       = "http://${azurerm_public_ip.appgw.ip_address}/python"
}

output "php_app_url" {
  description = "PHP status app URL (via the Application Gateway)"
  value       = "http://${azurerm_public_ip.appgw.ip_address}/php"
}

output "mysql_host" {
  description = "Azure Database for MySQL Flexible Server fully-qualified domain name (public endpoint, gated by firewall rules)."
  value       = azurerm_mysql_flexible_server.main.fqdn
}

output "mysql_port" {
  description = "MySQL port."
  value       = 3306
}

output "redis_host" {
  description = "Azure Cache for Redis hostname (public endpoint, gated by firewall rules)."
  value       = azurerm_redis_cache.main.hostname
}

output "redis_port" {
  description = "Azure Cache for Redis port. The non-SSL port is disabled on this cache, so ssl_port is the only port that accepts connections."
  value       = azurerm_redis_cache.main.ssl_port
}
