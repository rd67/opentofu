# Managed MySQL cluster, placed in the VPC so it's reachable over a private
# address (private_host) rather than the public internet.
resource "digitalocean_database_cluster" "mysql" {
  name                 = "${local.name_prefix}-mysql"
  engine               = "mysql"
  version              = "8.4"
  size                 = var.mysql_size
  region               = var.region
  node_count           = 1
  private_network_uuid = digitalocean_vpc.main.id
  tags                 = local.tags
}

# An application-level user in addition to DigitalOcean's built-in `doadmin`
# user. Note: DigitalOcean generates this user's password itself - unlike
# RDS/Cloud SQL/Azure Flexible Server, there is no argument to set it to a
# chosen value. Retrieve it after apply with:
#   tofu output -raw mysql_app_password
resource "digitalocean_database_user" "app" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = var.db_username
}

# Restrict the cluster to only the three app droplets (plus, implicitly,
# nothing else - no CIDR/public access is granted).
resource "digitalocean_database_firewall" "mysql" {
  cluster_id = digitalocean_database_cluster.mysql.id

  dynamic "rule" {
    for_each = digitalocean_droplet.app
    content {
      type  = "droplet"
      value = rule.value.id
    }
  }
}
