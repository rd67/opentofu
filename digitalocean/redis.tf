# Managed Redis-compatible cache. DigitalOcean stopped offering new
# Redis-engine clusters in favor of Valkey (a Redis-protocol-compatible,
# open-source fork) - "engine = valkey" is the current way to provision a
# Redis-compatible managed cache here. The app-facing wire protocol,
# host/port, and TCP reachability check are unchanged either way. Verify
# against the current DigitalOcean provider docs
# (registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/database_cluster)
# if this ever needs to move back to engine = "redis".
resource "digitalocean_database_cluster" "redis" {
  name                 = "${local.name_prefix}-cache"
  engine               = "valkey"
  version              = "8"
  size                 = var.redis_size
  region               = var.region
  node_count           = 1
  private_network_uuid = digitalocean_vpc.main.id
  tags                 = local.tags
}

resource "digitalocean_database_firewall" "redis" {
  cluster_id = digitalocean_database_cluster.redis.id

  dynamic "rule" {
    for_each = digitalocean_droplet.app
    content {
      type  = "droplet"
      value = rule.value.id
    }
  }
}
