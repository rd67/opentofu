resource "digitalocean_ssh_key" "main" {
  name       = "${local.name_prefix}-key"
  public_key = var.ssh_public_key
}

# --- App droplets -----------------------------------------------------------

locals {
  apps = {
    node = {
      port       = 3000
      cloud_init = "../apps/node/cloud-init.yaml.tpl"
      source     = "../apps/node/server.js"
      router     = null
      extra_env  = var.node_env
    }
    python = {
      port       = 4000
      cloud_init = "../apps/python/cloud-init.yaml.tpl"
      source     = "../apps/python/server.py"
      router     = null
      extra_env  = var.python_env
    }
    php = {
      port       = 5000
      cloud_init = "../apps/php/cloud-init.yaml.tpl"
      source     = "../apps/php/index.php"
      router     = "../apps/php/router.php"
      extra_env  = var.php_env
    }
  }
}

resource "digitalocean_droplet" "app" {
  for_each = local.apps

  name     = "${local.name_prefix}-${each.key}"
  region   = var.region
  size     = var.droplet_size
  image    = "ubuntu-22-04-x64"
  vpc_uuid = digitalocean_vpc.main.id
  ssh_keys = [digitalocean_ssh_key.main.fingerprint]
  tags     = local.tags

  # Renders the shared, dependency-free status app for this language and
  # wires it to the managed MySQL/Valkey endpoints (plus any custom
  # node_env/python_env/php_env vars) via a generated env file, following
  # the fixed contract documented in ../apps/README.md. PHP additionally
  # needs app_port (baked into its systemd ExecStart) and app_router_b64
  # (its built-in-server router script, required for path-based routing -
  # see ../apps/README.md and loadbalancer.tf).
  user_data = templatefile(each.value.cloud_init, merge(
    {
      app_port       = each.value.port
      app_source_b64 = filebase64(each.value.source)
      app_env_b64 = base64encode(join("\n", [
        for k, v in merge({
          APP_PORT   = tostring(each.value.port)
          MYSQL_HOST = digitalocean_database_cluster.mysql.private_host
          MYSQL_PORT = tostring(digitalocean_database_cluster.mysql.port)
          REDIS_HOST = digitalocean_database_cluster.redis.private_host
          REDIS_PORT = tostring(digitalocean_database_cluster.redis.port)
        }, each.value.extra_env) : "${k}=${v}"
      ]))
    },
    each.value.router != null ? { app_router_b64 = filebase64(each.value.router) } : {}
  ))
}

# --- Firewall -----------------------------------------------------------
# DigitalOcean Cloud Firewalls deny all outbound traffic by default once
# attached unless outbound rules are explicitly declared - unlike an AWS
# security group or Azure NSG. The outbound rules below intentionally allow
# everything so the droplets can still reach the internet (apt, etc.) and
# the managed database cluster over the VPC.
#
# App ports are only reachable from the edge droplet (see loadbalancer.tf) -
# the DigitalOcean Load Balancer -> nginx edge droplet is now the only
# public entry point for app traffic, not these droplets directly.

resource "digitalocean_firewall" "app" {
  name        = "${local.name_prefix}-fw"
  droplet_ids = [for d in digitalocean_droplet.app : d.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.allowed_ssh_cidr]
  }

  dynamic "inbound_rule" {
    for_each = local.apps
    content {
      protocol           = "tcp"
      port_range         = tostring(inbound_rule.value.port)
      source_droplet_ids = [digitalocean_droplet.edge.id]
    }
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
