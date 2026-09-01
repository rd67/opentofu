terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      # As of writing, hashicorp/google is at v8.x. Verified against the
      # provider docs that none of the v7/v8 upgrade guides' breaking
      # changes affect the resources used in this module (google_compute_*,
      # google_sql_database_instance, google_redis_instance,
      # google_service_networking_connection, google_project_service), so a
      # wide range is used rather than pinning to a single stale major.
      version = ">= 6.0.0, < 9.0.0"
    }
  }
}
