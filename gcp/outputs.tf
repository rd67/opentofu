output "lb_url" {
  description = "Load balancer URL (path-routes to all three apps: /nodejs -> node, /python -> python, /php -> php)."
  value       = "http://${google_compute_global_address.lb_ip.address}"
}

output "node_app_url" {
  description = "URL of the Node.js status app (via the load balancer)."
  value       = "http://${google_compute_global_address.lb_ip.address}/nodejs"
}

output "python_app_url" {
  description = "URL of the Python status app (via the load balancer)."
  value       = "http://${google_compute_global_address.lb_ip.address}/python"
}

output "php_app_url" {
  description = "URL of the PHP status app (via the load balancer)."
  value       = "http://${google_compute_global_address.lb_ip.address}/php"
}

output "mysql_host" {
  description = "Private IP address of the Cloud SQL (MySQL) instance."
  value       = google_sql_database_instance.mysql.private_ip_address
}

output "mysql_port" {
  description = "Port MySQL listens on."
  value       = 3306
}

output "redis_host" {
  description = "Private IP address / hostname of the Memorystore Redis instance."
  value       = google_redis_instance.cache.host
}

output "redis_port" {
  description = "Port Redis listens on."
  value       = google_redis_instance.cache.port
}
