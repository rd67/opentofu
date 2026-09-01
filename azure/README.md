# Azure - OpenTofu starter

Provisions three tiny app VMs (Node.js, Python, PHP) behind an Application
Gateway, a managed MySQL database (Azure Database for MySQL), and a managed
Redis cache (Azure Cache for Redis) on Azure. See the
[root README](../README.md) for the shared architecture diagram and how
load balancing / environment variables work.

Unlike AWS/DigitalOcean, Azure doesn't need an extra "project" resource
added here - every resource in this module already lives inside its own
Resource Group (`azurerm_resource_group.main`), Azure's own first-class
grouping container, by construction.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.6
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli),
  authenticated: `az login` (and `az account set --subscription "<id>"` if
  you have more than one)
- An SSH key pair (`ssh-keygen -t ed25519` if you don't have one)
- Your own public IP, for `allowed_ssh_cidr` (`curl -s https://ifconfig.me`)

## Quickstart

```bash
cd azure
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars   # set allowed_ssh_cidr, ssh_public_key, db_admin_password

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

## What gets created & cost

- A resource group, a VNet with two subnets, and two NSGs
- 3x Linux VM (`Standard_B1s` - Azure's free-tier size, 750 free hours/month
  for 12 months)
- Azure Database for MySQL Flexible Server (`B_Standard_B1ms` - also
  covered by Azure's 12-month free tier)
- Azure Cache for Redis (`Basic`, 250 MB - the smallest size; no free tier)
- An Application Gateway (`Standard_v2`, fixed capacity 1 - the smallest
  configuration, but **not** free-tier eligible)

**Estimated cost**: dominated by the Application Gateway - **roughly
$150+/month** even with everything else on the free tier, since Standard_v2
bills an hourly charge plus per-capacity-unit charges regardless of usage.
This is a real outlier among the four providers in this repo. Run
`tofu destroy` when you're done experimenting.

## Learn more

- Architecture diagram, load balancing, and environment variables (same
  mechanism for all four providers): [root README](../README.md)
- Azure-specific details (why the Application Gateway needs its own
  subnet/NSG, the public-endpoint + IP-allowlist networking model for
  MySQL/Redis): see the comments in `network.tf`, `loadbalancer.tf`,
  `database.tf`, and `redis.tf` in this folder.
