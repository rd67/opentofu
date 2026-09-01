# --- Edge reverse-proxy droplet -------------------------------------------
# DigitalOcean's Load Balancer product only does protocol/port forwarding -
# it has no path-based routing. To get the same single-entry-point,
# path-routed behavior the other three providers get from their native L7
# load balancers, this module adds a small nginx reverse-proxy droplet
# ("edge") that does the path routing, then puts DigitalOcean's Load
# Balancer in front of that one droplet (for a stable public IP and health
# checks). See README.md for the full rationale and diagram.

resource "digitalocean_droplet" "edge" {
  name     = "${local.name_prefix}-edge"
  region   = var.region
  size     = var.droplet_size
  image    = "ubuntu-22-04-x64"
  vpc_uuid = digitalocean_vpc.main.id
  ssh_keys = [digitalocean_ssh_key.main.fingerprint]
  tags     = local.tags

  user_data = templatefile("${path.module}/edge-cloud-init.yaml.tpl", {
    node_host   = digitalocean_droplet.app["node"].ipv4_address_private
    node_port   = local.apps["node"].port
    python_host = digitalocean_droplet.app["python"].ipv4_address_private
    python_port = local.apps["python"].port
    php_host    = digitalocean_droplet.app["php"].ipv4_address_private
    php_port    = local.apps["php"].port
  })
}

resource "digitalocean_loadbalancer" "main" {
  name     = "${local.name_prefix}-lb"
  region   = var.region
  vpc_uuid = digitalocean_vpc.main.id

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 80
  }

  healthcheck {
    protocol = "http"
    port     = 80
    path     = "/"
  }

  droplet_ids = [digitalocean_droplet.edge.id]
}

# The edge droplet only accepts HTTP from the load balancer itself (not the
# open internet - the load balancer is the actual internet-facing
# endpoint), plus SSH from the operator. Same explicit-outbound-allow
# pattern as digitalocean_firewall.app in compute.tf, since DigitalOcean
# Cloud Firewalls deny all outbound traffic by default once attached.
resource "digitalocean_firewall" "edge" {
  name        = "${local.name_prefix}-edge-fw"
  droplet_ids = [digitalocean_droplet.edge.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.allowed_ssh_cidr]
  }

  inbound_rule {
    protocol                  = "tcp"
    port_range                = "80"
    source_load_balancer_uids = [digitalocean_loadbalancer.main.id]
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
