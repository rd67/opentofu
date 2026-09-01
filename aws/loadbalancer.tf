# --- Application Load Balancer, path-based routing -------------------------
# Single public entry point: /nodejs* -> node, /python* -> python, /php* -> php.
# The ALB is the only thing allowed to reach the app instances on their app
# ports (see aws_security_group.app in compute.tf) - the EC2 instances are no
# longer directly reachable on 3000/4000/5000 from the internet.

resource "aws_security_group" "lb" {
  name        = "${var.project_name}-${var.environment}-lb-sg"
  description = "ALB: HTTP from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-lb-sg"
  })
}

resource "aws_lb" "app" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "node" {
  name        = "${var.project_name}-${var.environment}-node-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "python" {
  name        = "${var.project_name}-${var.environment}-python-tg"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "php" {
  name        = "${var.project_name}-${var.environment}-php-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.common_tags
}

resource "aws_lb_target_group_attachment" "node" {
  target_group_arn = aws_lb_target_group.node.arn
  target_id        = aws_instance.node.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "python" {
  target_group_arn = aws_lb_target_group.python.arn
  target_id        = aws_instance.python.id
  port             = 4000
}

resource "aws_lb_target_group_attachment" "php" {
  target_group_arn = aws_lb_target_group.php.arn
  target_id        = aws_instance.php.id
  port             = 5000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  # Falls back to the Node.js app for any path that doesn't match one of the
  # explicit rules below (e.g. the bare "/") - a convenience, not the
  # documented contract. The documented, symmetric way to reach each app is
  # /nodejs*, /python*, /php*.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node.arn
  }
}

resource "aws_lb_listener_rule" "node" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 5

  condition {
    path_pattern {
      values = ["/nodejs", "/nodejs/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node.arn
  }
}

resource "aws_lb_listener_rule" "python" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/python", "/python/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.python.arn
  }
}

resource "aws_lb_listener_rule" "php" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  condition {
    path_pattern {
      values = ["/php", "/php/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.php.arn
  }
}
