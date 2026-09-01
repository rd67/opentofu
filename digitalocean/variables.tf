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

variable "region" {
  description = "DigitalOcean region slug for all resources."
  type        = string
  default     = "nyc3"
}

variable "do_token" {
  description = <<-EOT
    DigitalOcean Personal Access Token (read + write scope).

    REQUIRED, sensitive - no default is provided. Create one at
    https://cloud.digitalocean.com/account/api/tokens, or via `doctl`. Do not
    commit this value; set it in terraform.tfvars (gitignored) or via the
    TF_VAR_do_token / DIGITALOCEAN_TOKEN environment variable.
  EOT
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = <<-EOT
    Public key material (the contents of, e.g., ~/.ssh/id_ed25519.pub) used
    to create the DigitalOcean SSH key for access to the droplets.

    REQUIRED - no default is provided. Generate a key pair with:
    `ssh-keygen -t ed25519` if you don't already have one.
  EOT
  type        = string
}

variable "allowed_ssh_cidr" {
  description = <<-EOT
    CIDR block allowed to SSH (port 22) into the app droplets.

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

variable "droplet_size" {
  description = "Droplet size slug for each app VM (and the edge proxy). s-1vcpu-512mb-10gb is DigitalOcean's cheapest droplet (~$4/month); DigitalOcean has no free tier."
  type        = string
  default     = "s-1vcpu-512mb-10gb"
}

variable "mysql_size" {
  description = "Node size slug for the managed MySQL database cluster."
  type        = string
  default     = "db-s-1vcpu-1gb"
}

variable "redis_size" {
  description = "Node size slug for the managed Redis-compatible (Valkey) database cluster."
  type        = string
  default     = "db-s-1vcpu-1gb"
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

variable "db_username" {
  description = <<-EOT
    Name of the application-level database user created in the managed
    MySQL cluster (in addition to DigitalOcean's built-in `doadmin` user).

    Note: DigitalOcean generates this user's password itself - it cannot be
    set to a chosen value the way RDS/Cloud SQL/Azure Flexible Server allow.
    Retrieve it after apply with:
    `tofu output -raw mysql_app_password`
  EOT
  type        = string
  default     = "appuser"
}
