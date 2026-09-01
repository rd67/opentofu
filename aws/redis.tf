# --- ElastiCache Redis ----------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-cache-subnet-group"
  subnet_ids = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cache-subnet-group"
  })
}

resource "aws_elasticache_cluster" "main" {
  cluster_id      = "${var.project_name}-${var.environment}-redis"
  engine          = "redis"
  engine_version  = "7.1"
  node_type       = var.cache_node_type
  num_cache_nodes = 1
  port            = 6379

  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.app.id]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-redis"
  })
}
