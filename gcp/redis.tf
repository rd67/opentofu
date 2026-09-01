# --- Required APIs -----------------------------------------------------------

resource "google_project_service" "redis" {
  project            = var.project_id
  service            = "redis.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# --- Memorystore (Redis) ------------------------------------------------------
#
# connect_mode = "PRIVATE_SERVICE_ACCESS" places the instance's private IP in
# the range reserved by the private-services-access peering (see network.tf)
# instead of Memorystore's older direct-peering model. This is what lets the
# same VPC peering plumbing serve both Cloud SQL and Memorystore.

resource "google_redis_instance" "cache" {
  name           = "${var.project_name}-${var.environment}-cache"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region

  authorized_network = google_compute_network.vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  redis_version = "REDIS_7_2"
  display_name  = "${var.project_name}-${var.environment}"
  labels        = local.labels

  depends_on = [
    google_project_service.redis,
    google_project_service.servicenetworking,
    google_service_networking_connection.private_service_connection,
  ]
}
