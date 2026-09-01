locals {
  labels = {
    project     = var.project_name
    environment = var.environment
  }
}

# --- VPC -------------------------------------------------------------------
# A fully custom VPC, independent of any "default" network GCP may have
# auto-created for this project. Unlike DigitalOcean, GCP never promotes a
# custom-created network to be un-deletable - `tofu destroy` removes it
# cleanly with no special handling required.

resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "app" {
  name          = "${var.project_name}-${var.environment}-app-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# --- Private Services Access ------------------------------------------------
#
# Why this exists: Cloud SQL with a *private* IP and Memorystore for Redis are
# not "in" your VPC the way a VM is - they live in a separate network owned by
# Google (the "service producer" network) and are only reachable from your VPC
# via VPC Network Peering. "Private Services Access" is the name for the
# one-time plumbing that sets up that peering:
#
#   1. Reserve a named internal IP range in YOUR VPC (google_compute_global_address,
#      purpose = "VPC_PEERING") - this range is handed to Google, not used by
#      your own resources.
#   2. Create a VPC peering connection between your VPC and
#      servicenetworking.googleapis.com (google_service_networking_connection),
#      referencing that reserved range.
#   3. Google then carves private IPs for Cloud SQL / Memorystore instances out
#      of that reserved range, and routes between your VPC and those IPs flow
#      over the peering - no public IP, no NAT, no internet exposure needed.
#
# Both the Cloud SQL instance (database.tf) and the Redis instance (redis.tf)
# depend on this connection existing first; the provider does not infer that
# dependency automatically, so it's expressed explicitly via depends_on on
# each resource.

resource "google_compute_global_address" "private_service_range" {
  name          = "${var.project_name}-${var.environment}-psa-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
  labels        = local.labels
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]

  depends_on = [google_project_service.servicenetworking]
}

# --- Firewall ----------------------------------------------------------------

resource "google_compute_firewall" "ssh" {
  name    = "${var.project_name}-${var.environment}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # REQUIRED: var.allowed_ssh_cidr has no default - the user must set it to
  # their own IP (see README "Find your public IP"). Never leave this as
  # 0.0.0.0/0.
  source_ranges = [var.allowed_ssh_cidr]
  target_tags   = ["starter-app"]
}

# NOTE: there is no longer a firewall rule allowing 0.0.0.0/0 direct to the
# app ports on the instances. Now that a load balancer fronts all three apps
# (see loadbalancer.tf), the only rule permitting inbound traffic on
# 3000/4000/5000 is google_compute_firewall.lb, scoped to Google's
# load-balancer/health-check source ranges - not the whole internet.

# Internal traffic within the subnet on the DB/cache ports. Note: this does
# NOT govern reachability to Cloud SQL/Memorystore themselves (that traffic
# crosses the private-services-access peering to Google's producer network,
# which is not controlled by VPC firewall rules on this network at all - the
# default allow-egress rule is what lets the app VMs reach it). This rule is
# kept for defense-in-depth / consistency with the other provider folders in
# this repo, and so anything self-hosted on the subnet (e.g. a bastion doing
# a manual mysql/redis-cli check) is not blocked by a later tightening of
# app_ports.
resource "google_compute_firewall" "internal_db_cache" {
  name    = "${var.project_name}-${var.environment}-allow-internal-db-cache"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["3306", "6379"]
  }

  source_ranges = [google_compute_subnetwork.app.ip_cidr_range]
  target_tags   = ["starter-app"]
}
