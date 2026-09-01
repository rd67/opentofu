# --- Shared tags -------------------------------------------------------

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}

# --- Availability zones -------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

# --- VPC ------------------------------------------------------------------
# A single custom VPC for this starter. Two AZs are used purely because
# aws_db_subnet_group (RDS) and aws_elasticache_subnet_group both require
# subnets spanning at least two Availability Zones - not because this
# workload needs multi-AZ redundancy.
#
# Unlike DigitalOcean, this custom VPC is never treated as an account-level
# "default" - AWS's per-region default VPC (which already exists regardless
# of this module) is a separate resource we never touch. `tofu destroy`
# removes this VPC cleanly with no special handling required.

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# --- Subnets --------------------------------------------------------------
# NOTE (simplification): both subnets are "public" (map_public_ip_on_launch
# = true, default route to the Internet Gateway). A production network would
# instead put the EC2 instances and/or the database/cache in private
# subnets behind a NAT Gateway, with only a bastion or load balancer
# exposed publicly. For a learn-by-reading starter that would add a NAT
# Gateway (which costs money per hour + per GB) and extra route-table
# plumbing without changing the app/DB/cache wiring being demonstrated, so
# this repo intentionally keeps everything in two public subnets.

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-${count.index}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
