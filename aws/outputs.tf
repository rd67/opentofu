output "lb_url" {
  description = "Load balancer URL. Path-routes to all three apps: /nodejs -> Node.js, /python -> Python, /php -> PHP."
  value       = "http://${aws_lb.app.dns_name}"
}

output "node_app_url" {
  description = "URL of the Node.js status app (via the load balancer)"
  value       = "http://${aws_lb.app.dns_name}/nodejs"
}

output "python_app_url" {
  description = "URL of the Python status app (via the load balancer)"
  value       = "http://${aws_lb.app.dns_name}/python"
}

output "php_app_url" {
  description = "URL of the PHP status app (via the load balancer)"
  value       = "http://${aws_lb.app.dns_name}/php"
}

output "mysql_host" {
  description = "RDS MySQL endpoint hostname"
  value       = aws_db_instance.main.address
}

output "mysql_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.main.port
}

output "redis_host" {
  description = "ElastiCache Redis endpoint hostname"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = aws_elasticache_cluster.main.cache_nodes[0].port
}
