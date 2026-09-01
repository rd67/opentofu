# --- External HTTP Load Balancer (path-based routing) ----------------------
#
# A classic external Application Load Balancer that path-routes a single
# public IP to all three apps: "/nodejs" and "/nodejs/*" -> node, "/python"
# and "/python/*" -> python, "/php" and "/php/*" -> php (the bare "/" also
# falls back to node, as a convenience). This is the GCP-native way to do
# path-based routing across multiple backends on one IP/port.
#
# Chain: forwarding rule -> target HTTP proxy -> URL map (path rules) ->
# backend services (one per app) -> unmanaged instance groups (one per app,
# each wrapping that app's single VM) -> the VMs themselves.

resource "google_compute_health_check" "app" {
  for_each = local.apps

  name                = "${var.project_name}-${var.environment}-${each.key}-hc"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = each.value.port
    request_path = "/"
  }
}

resource "google_compute_instance_group" "app" {
  for_each = local.apps

  name      = "${var.project_name}-${var.environment}-${each.key}-ig"
  zone      = var.zone
  instances = [google_compute_instance.app[each.key].id]

  named_port {
    name = "http"
    port = each.value.port
  }
}

resource "google_compute_backend_service" "app" {
  for_each = local.apps

  name                  = "${var.project_name}-${var.environment}-${each.key}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL"
  timeout_sec           = 30
  health_checks         = [google_compute_health_check.app[each.key].id]

  backend {
    group = google_compute_instance_group.app[each.key].id
  }
}

resource "google_compute_url_map" "app" {
  name            = "${var.project_name}-${var.environment}-urlmap"
  default_service = google_compute_backend_service.app["node"].id

  host_rule {
    hosts        = ["*"]
    path_matcher = "apps"
  }

  path_matcher {
    name = "apps"
    # Falls back to the Node.js backend for any path that doesn't match a
    # rule below (e.g. the bare "/") - a convenience, not the documented
    # contract. The documented, symmetric way to reach each app is
    # /nodejs*, /python*, /php*.
    default_service = google_compute_backend_service.app["node"].id

    path_rule {
      paths   = ["/nodejs", "/nodejs/*"]
      service = google_compute_backend_service.app["node"].id
    }

    path_rule {
      paths   = ["/python", "/python/*"]
      service = google_compute_backend_service.app["python"].id
    }

    path_rule {
      paths   = ["/php", "/php/*"]
      service = google_compute_backend_service.app["php"].id
    }
  }
}

resource "google_compute_target_http_proxy" "app" {
  name    = "${var.project_name}-${var.environment}-http-proxy"
  url_map = google_compute_url_map.app.id
}

resource "google_compute_global_address" "lb_ip" {
  name = "${var.project_name}-${var.environment}-lb-ip"
}

resource "google_compute_global_forwarding_rule" "app" {
  name                  = "${var.project_name}-${var.environment}-fwd-rule"
  target                = google_compute_target_http_proxy.app.id
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL"
}

# Traffic to the app ports now comes from Google's load balancer/health-check
# infrastructure, not directly from the public internet. 130.211.0.0/22 and
# 35.191.0.0/16 are Google's documented source ranges for BOTH health checks
# and actual proxied backend traffic for this (classic external HTTP(S))
# load balancer type - a single firewall rule covers both.
resource "google_compute_firewall" "lb" {
  name    = "${var.project_name}-${var.environment}-allow-lb"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["3000", "4000", "5000"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["starter-app"]
}
