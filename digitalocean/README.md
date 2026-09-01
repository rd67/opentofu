# DigitalOcean - OpenTofu starter

Provisions three tiny app VMs (Node.js, Python, PHP) behind a load balancer,
a managed MySQL database, and a managed Valkey (Redis-compatible) cache on
DigitalOcean. See the [root README](../README.md) for the shared
architecture diagram and how load balancing / environment variables work.

DigitalOcean's Load Balancer can't route by URL path on its own, so this
folder adds one extra piece the other three providers don't need: a small
nginx "edge" droplet that does the actual path routing, sitting behind the
Load Balancer. See the comments in `loadbalancer.tf` for details.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.6
- A DigitalOcean Personal Access Token (create one at
  https://cloud.digitalocean.com/account/api/tokens)
- An SSH key pair (`ssh-keygen -t ed25519` if you don't have one)
- Your own public IP, for `allowed_ssh_cidr` (`curl ifconfig.me`)

## Quickstart

```bash
cd digitalocean
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars   # set do_token, allowed_ssh_cidr, ssh_public_key

tofu init
tofu plan
tofu apply
```

```bash
tofu output   # lb_url, node_app_url/python_app_url/php_app_url, mysql/redis endpoints
```

```bash
tofu destroy   # tear down when done
```

**If this is the first time your team has used a VPC in this region**,
`tofu destroy` will remove every billable resource successfully but then
fail on the VPC itself with `403 Can not delete default VPCs` - this is
expected DigitalOcean behavior (see the comment above
`digitalocean_vpc.main` in `network.tf`), not a bug, and the leftover VPC
costs nothing. Finish cleanup with:

```bash
tofu state rm digitalocean_vpc.main
```

## Useful `doctl` commands

Handy for verifying which team you're about to deploy into, and for
diagnosing account-limit errors before/during `tofu apply`:

```bash
# One-time: authenticate a named context (safer than a bare `doctl auth init`
# if you belong to multiple teams) - paste your Personal Access Token when prompted
doctl auth init --context my-team
doctl auth switch --context my-team

# Confirm which team/account a token is scoped to, and check resource limits
# (e.g. "droplet_limit") before applying - a low droplet limit on a new/unverified
# account can cause `tofu apply` to fail partway through with
# "creating this/these droplet(s) will exceed your droplet limit in <region>"
doctl account get

# See exactly which droplets currently count against that limit
doctl compute droplet list
```

If you hit the droplet-limit error above, request an increase in the
DigitalOcean console under **Settings → Limits** (with the right team
active) - this isn't something the API/CLI can do on its own.

All resources are also grouped into a DigitalOcean **Project** named after
`var.project_name` (see `project.tf`), so they show up together in the
console instead of mixed into "My Team"'s default project - purely
organizational, doesn't affect networking or billing.

## What gets created & cost

- A Project (groups the resources below in the console)
- A VPC and firewalls
- 4x Droplet (3 apps + 1 nginx edge proxy), `s-1vcpu-512mb-10gb` -
  DigitalOcean's cheapest droplet, ~$4/month each
- A managed MySQL database cluster (`db-s-1vcpu-1gb` - DigitalOcean's
  smallest managed database size, ~$15/month)
- A managed Valkey (Redis-compatible) database cluster (same size, ~$15/month)
- A Load Balancer (~$12/month)

**Estimated cost**: roughly $58/month - DigitalOcean has no free tier, and
this is the only provider in this repo that needs a 4th VM (the edge
proxy) plus an always-on Load Balancer. Run `tofu destroy` when you're done
experimenting.

One more DigitalOcean-specific quirk: it doesn't let you choose the
database password - it's generated automatically. Retrieve it with
`tofu output -raw mysql_app_password` if you need it (the apps themselves
don't - they only do a TCP reachability check).

## Learn more

- Architecture diagram, load balancing, and environment variables (same
  mechanism for all four providers): [root README](../README.md)
- DigitalOcean-specific details (the nginx edge proxy, droplet-scoped
  database firewalls): see the comments in `loadbalancer.tf`,
  `edge-cloud-init.yaml.tpl`, `compute.tf`, and `database.tf` in this
  folder.
