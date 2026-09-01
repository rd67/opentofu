# Auth via var.do_token (a Personal Access Token). No credentials are
# hardcoded here on purpose - set do_token in terraform.tfvars (gitignored)
# or via the TF_VAR_do_token / DIGITALOCEAN_TOKEN environment variable.
provider "digitalocean" {
  token = var.do_token
}
