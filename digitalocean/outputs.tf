output "lb_url" {
  description = "Load balancer URL - path-routes to all three apps via the nginx edge droplet"
  value       = "http://${digitalocean_loadbalancer.main.ip}"
}

output "node_app_url" {
  description = "URL of the Node.js status app (via the load balancer)"
  value       = "http://${digitalocean_loadbalancer.main.ip}/nodejs"
}

output "python_app_url" {
  description = "URL of the Python status app (via the load balancer)"
  value       = "http://${digitalocean_loadbalancer.main.ip}/python"
}

output "php_app_url" {
  description = "URL of the PHP status app (via the load balancer)"
  value       = "http://${digitalocean_loadbalancer.main.ip}/php"
}

output "mysql_host" {
  description = "Private hostname of the managed MySQL cluster (reachable from within the VPC)"
  value       = digitalocean_database_cluster.mysql.private_host
}

output "mysql_port" {
  description = "Managed MySQL cluster port"
  value       = digitalocean_database_cluster.mysql.port
}

output "redis_host" {
  description = "Private hostname of the managed Redis-compatible (Valkey) cluster"
  value       = digitalocean_database_cluster.redis.private_host
}

output "redis_port" {
  description = "Managed Redis-compatible (Valkey) cluster port"
  value       = digitalocean_database_cluster.redis.port
}

output "mysql_app_password" {
  description = "Auto-generated password for the app-level MySQL user (var.db_username). DigitalOcean generates this; it cannot be set to a chosen value."
  value       = digitalocean_database_user.app.password
  sensitive   = true
}
