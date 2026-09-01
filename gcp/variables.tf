variable "project_id" {
  description = "Existing GCP project ID (must have billing enabled). Not created by this config."
  type        = string
}

variable "project_name" {
  description = "Short name used to prefix/label resources."
  type        = string
  default     = "tofu-starter"
}

variable "environment" {
  description = "Environment label (dev, staging, prod, ...)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "GCP region for all regional resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone (within region) for the Compute Engine instances."
  type        = string
  default     = "us-central1-a"
}

variable "ssh_public_key" {
  description = "SSH public key content (e.g. contents of ~/.ssh/id_ed25519.pub) granted access to the VMs as ssh_username."
  type        = string
}

variable "ssh_username" {
  description = "Username to associate with ssh_public_key on each VM (GCP's guest agent creates this account from instance metadata)."
  type        = string
  default     = "tofu"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to reach the VMs on port 22. REQUIRED - set this to your own IP/32 (see README for how to find it). Do not leave it open to 0.0.0.0/0."
  type        = string
}

variable "machine_type" {
  description = "Compute Engine machine type for each app VM. e2-micro is the smallest available and is covered by GCP's Always Free tier (one instance/month, in select US regions including the default us-central1)."
  type        = string
  default     = "e2-micro"
}

variable "db_tier" {
  description = "Cloud SQL machine tier. db-f1-micro is a shared-core dev/test tier - size up for anything beyond a starter."
  type        = string
  default     = "db-f1-micro"
}

variable "db_username" {
  description = "Application username created in Cloud SQL for MySQL."
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Password for the application MySQL user."
  type        = string
  sensitive   = true
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
