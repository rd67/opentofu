# --- Required API -----------------------------------------------------------

resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# --- App VMs -----------------------------------------------------------------

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

resource "google_compute_instance" "app" {
  for_each     = local.apps
  name         = "${var.project_name}-${var.environment}-${each.key}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["starter-app"]
  labels       = merge(local.labels, { app = each.key })

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.app.id
    access_config {} # ephemeral public IP - kept for SSH; app ports are no
    # longer opened to 0.0.0.0/0 directly, see network.tf
    # and loadbalancer.tf
  }

  # Renders the shared, dependency-free status app for this language and
  # wires it to the managed MySQL/Redis endpoints (plus any custom
  # node_env/python_env/php_env vars) via a generated env file, following
  # the fixed contract documented in ../apps/README.md. PHP additionally
  # needs app_port (baked into its systemd ExecStart) and app_router_b64
  # (its built-in-server router script, required for path-based routing -
  # see ../apps/README.md).
  metadata = {
    user-data = templatefile(each.value.cloud_init, merge(
      {
        app_port       = each.value.port
        app_source_b64 = filebase64(each.value.source)
        app_env_b64 = base64encode(join("\n", [
          for k, v in merge({
            APP_PORT   = tostring(each.value.port)
            MYSQL_HOST = google_sql_database_instance.mysql.private_ip_address
            MYSQL_PORT = "3306"
            REDIS_HOST = google_redis_instance.cache.host
            REDIS_PORT = tostring(google_redis_instance.cache.port)
          }, each.value.extra_env) : "${k}=${v}"
        ]))
      },
      each.value.router != null ? { app_router_b64 = filebase64(each.value.router) } : {}
    ))
    ssh-keys = "${var.ssh_username}:${var.ssh_public_key}"
  }

  depends_on = [
    google_project_service.compute,
    google_compute_firewall.ssh,
    google_compute_firewall.lb,
  ]
}
