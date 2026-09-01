# --- AMI lookup -----------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# --- Security group ---------------------------------------------------
# One shared security group for the app VMs, RDS, and ElastiCache: SSH from
# the operator's own IP, the three app ports only from the load balancer
# (see loadbalancer.tf - the ALB is now the only public entry point for app
# traffic), and MySQL/Redis only from members of this same security group
# (i.e. the app VMs themselves, plus RDS/ElastiCache which are also placed
# in this group).

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "App VMs, RDS, and ElastiCache: SSH, LB-only app ports, and self-referencing DB/cache access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from the operator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description     = "Node.js app, from the load balancer only"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    description     = "Python app, from the load balancer only"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    description     = "PHP app, from the load balancer only"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  ingress {
    description = "MySQL from members of this security group"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Redis from members of this security group"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-sg"
  })
}

# --- Key pair ---------------------------------------------------------

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = var.ssh_public_key

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-key"
  })
}

# --- App instances ------------------------------------------------------
# Each instance renders the shared cloud-init template for its language
# with the fixed apps/ variable contract (app_port, mysql_host, mysql_port,
# redis_host, redis_port), pointed at the RDS and ElastiCache endpoints
# below.

resource "aws_instance" "node" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.main.key_name

  user_data = templatefile("${path.module}/../apps/node/cloud-init.yaml.tpl", {
    app_source_b64 = filebase64("${path.module}/../apps/node/server.js")
    app_env_b64 = base64encode(join("\n", [
      for k, v in merge({
        APP_PORT   = "3000"
        MYSQL_HOST = aws_db_instance.main.address
        MYSQL_PORT = tostring(aws_db_instance.main.port)
        REDIS_HOST = aws_elasticache_cluster.main.cache_nodes[0].address
        REDIS_PORT = tostring(aws_elasticache_cluster.main.cache_nodes[0].port)
      }, var.node_env) : "${k}=${v}"
    ]))
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-node"
  })
}

resource "aws_instance" "python" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.main.key_name

  user_data = templatefile("${path.module}/../apps/python/cloud-init.yaml.tpl", {
    app_source_b64 = filebase64("${path.module}/../apps/python/server.py")
    app_env_b64 = base64encode(join("\n", [
      for k, v in merge({
        APP_PORT   = "4000"
        MYSQL_HOST = aws_db_instance.main.address
        MYSQL_PORT = tostring(aws_db_instance.main.port)
        REDIS_HOST = aws_elasticache_cluster.main.cache_nodes[0].address
        REDIS_PORT = tostring(aws_elasticache_cluster.main.cache_nodes[0].port)
      }, var.python_env) : "${k}=${v}"
    ]))
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-python"
  })
}

resource "aws_instance" "php" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = aws_key_pair.main.key_name

  user_data = templatefile("${path.module}/../apps/php/cloud-init.yaml.tpl", {
    app_port       = 5000
    app_source_b64 = filebase64("${path.module}/../apps/php/index.php")
    app_router_b64 = filebase64("${path.module}/../apps/php/router.php")
    app_env_b64 = base64encode(join("\n", [
      for k, v in merge({
        APP_PORT   = "5000"
        MYSQL_HOST = aws_db_instance.main.address
        MYSQL_PORT = tostring(aws_db_instance.main.port)
        REDIS_HOST = aws_elasticache_cluster.main.cache_nodes[0].address
        REDIS_PORT = tostring(aws_elasticache_cluster.main.cache_nodes[0].port)
      }, var.php_env) : "${k}=${v}"
    ]))
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-php"
  })
}
