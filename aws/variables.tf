variable "project_name" {
  description = "Name prefix used to tag and name all resources."
  type        = string
  default     = "tofu-starter"
}

variable "environment" {
  description = "Deployment environment label (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "allowed_ssh_cidr" {
  description = <<-EOT
    CIDR block allowed to SSH (port 22) into the app instances.

    REQUIRED - no default is provided on purpose, so you don't accidentally
    leave SSH open to the entire internet. Set this to your own public IP in
    CIDR notation, e.g. "203.0.113.10/32". Find your current public IP with:
    `curl ifconfig.me`.
  EOT
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "allowed_ssh_cidr must be a valid CIDR block, e.g. 203.0.113.10/32."
  }
}

variable "ssh_public_key" {
  description = <<-EOT
    Public key material (the contents of, e.g., ~/.ssh/id_ed25519.pub) used
    to create the AWS key pair for SSH access to the instances.

    REQUIRED - no default is provided. Generate a key pair with:
    `ssh-keygen -t ed25519` if you don't already have one.
  EOT
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the three app VMs."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class for the MySQL database."
  type        = string
  default     = "db.t3.micro"
}

variable "cache_node_type" {
  description = "ElastiCache node type for the Redis cluster."
  type        = string
  default     = "cache.t3.micro"
}

variable "db_username" {
  description = "Master username for the RDS MySQL instance."
  type        = string
  default     = "appuser"
}

variable "node_env" {
  description = "Extra environment variables for the Node.js app (map of KEY=VALUE), merged on top of the fixed APP_PORT/MYSQL_*/REDIS_* ones this module sets automatically. Avoid reusing those names."
  type        = map(string)
  default     = {}
}

variable "python_env" {
  description = "Extra environment variables for the Python app (map of KEY=VALUE), merged on top of the fixed APP_PORT/MYSQL_*/REDIS_* ones this module sets automatically. Avoid reusing those names."
  type        = map(string)
  default     = {}
}

variable "php_env" {
  description = "Extra environment variables for the PHP app (map of KEY=VALUE), merged on top of the fixed APP_PORT/MYSQL_*/REDIS_* ones this module sets automatically. Avoid reusing those names."
  type        = map(string)
  default     = {}
}

variable "db_password" {
  description = <<-EOT
    Master password for the RDS MySQL instance.

    REQUIRED, sensitive - no default is provided. Must be 8-41 characters
    per RDS requirements. Do not commit this value; set it in
    terraform.tfvars (which is gitignored) or via TF_VAR_db_password.
  EOT
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8 && length(var.db_password) <= 41
    error_message = "db_password must be between 8 and 41 characters (RDS requirement)."
  }
}
