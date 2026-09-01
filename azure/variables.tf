variable "project_name" {
  description = "Short name used to prefix/tag all resources."
  type        = string
  default     = "tofu-starter"
}

variable "environment" {
  description = "Environment label (dev, staging, prod, ...)."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to reach the VMs on port 22. REQUIRED - set this to your own IP (e.g. 203.0.113.10/32). Do not leave it open to 0.0.0.0/0. Find your IP with `curl -s https://ifconfig.me`."
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content (e.g. contents of ~/.ssh/id_ed25519.pub) granted access to the VMs. REQUIRED - no default."
  type        = string
}

variable "admin_username" {
  description = "Admin username created on each VM."
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Azure VM size for each app VM."
  type        = string
  default     = "Standard_B1s"
}

variable "db_admin_username" {
  description = "Administrator login for the MySQL Flexible Server."
  type        = string
  default     = "appadmin"
}

variable "db_admin_password" {
  description = "Administrator password for the MySQL Flexible Server. REQUIRED - no default. Must meet Azure's MySQL password complexity requirements (8-128 chars, 3 of: upper/lower/digit/symbol)."
  type        = string
  sensitive   = true
}

variable "mysql_sku_name" {
  description = "SKU for the MySQL Flexible Server. B_Standard_B1ms is the smallest viable burstable tier suitable for a starter/dev workload."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "redis_sku_name" {
  description = "SKU for Azure Cache for Redis: Basic, Standard, or Premium."
  type        = string
  default     = "Basic"
}

variable "redis_family" {
  description = "SKU family for Azure Cache for Redis: 'C' for Basic/Standard, 'P' for Premium."
  type        = string
  default     = "C"
}

variable "redis_capacity" {
  description = "SKU capacity/size for Azure Cache for Redis. For family 'C': 0 (250MB) through 6 (53GB). 0 is the smallest viable size."
  type        = number
  default     = 0
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
