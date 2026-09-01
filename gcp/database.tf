# --- Required API -----------------------------------------------------------

resource "google_project_service" "sqladmin" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

# --- Cloud SQL (MySQL) -------------------------------------------------------
#
# Private-IP only (ipv4_enabled = false): the instance is reachable solely
# from within the VPC over the private-services-access peering set up in
# network.tf. See network.tf for why that peering is required.

resource "google_sql_database_instance" "mysql" {
  name             = "${var.project_name}-${var.environment}-mysql"
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier        = var.db_tier
    user_labels = local.labels

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.self_link
    }
  }

  # Starter-friendly default so `tofu destroy` isn't blocked. Flip to true
  # before treating this as anything beyond a throwaway environment.
  deletion_protection = false

  depends_on = [
    google_project_service.sqladmin,
    google_service_networking_connection.private_service_connection,
  ]
}

resource "google_sql_database" "app" {
  name     = "${var.project_name}_${var.environment}"
  instance = google_sql_database_instance.mysql.name
}

resource "google_sql_user" "app" {
  name     = var.db_username
  instance = google_sql_database_instance.mysql.name
  password = var.db_password
}
