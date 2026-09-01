locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags        = [var.project_name, var.environment]
}

# IMPORTANT - a DigitalOcean-specific quirk you WILL hit on `tofu destroy`:
#
# If your team has never had a VPC in `var.region` before, DigitalOcean
# automatically promotes the first one created there (this one) to be that
# region's "default VPC". Default VPCs can never be deleted via the API or
# the console - only renamed - so `tofu destroy` will successfully remove
# every other (billable) resource, then fail on this one with:
#
#   Error: DELETE .../vpcs/<id>: 403 Can not delete default VPCs
#
# This is expected DigitalOcean behavior, not a bug in this config, and it
# costs nothing to leave behind (VPCs themselves are free). To finish
# cleanup, run:
#
#   tofu state rm digitalocean_vpc.main
#
# This only stops OpenTofu from tracking the leftover VPC - it does not
# touch your DigitalOcean account. If you plan to `tofu apply` this module
# again later in the same region, either rename the leftover VPC first or
# change `project_name`/`environment`, since a new VPC with the same name
# would otherwise collide with it.
resource "digitalocean_vpc" "main" {
  name     = "${local.name_prefix}-vpc"
  region   = var.region
  ip_range = "10.10.0.0/16"
}
