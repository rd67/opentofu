# GCP - OpenTofu starter

Provisions three tiny app VMs (Node.js, Python, PHP) behind an external HTTP
load balancer, a managed MySQL database (Cloud SQL), and a managed Redis
cache (Memorystore) on GCP. See the [root README](../README.md) for the
shared architecture diagram and how load balancing / environment variables
work.

Unlike AWS/DigitalOcean, GCP doesn't need an extra "project" resource added
here - every resource in this module already lives inside `var.project_id`,
GCP's own first-class project container, by construction.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.6
- A GCP project with billing enabled (this config enables the required APIs
  inside it but does not create the project itself)
- Application Default Credentials: `gcloud auth application-default login`
- An SSH key pair (`ssh-keygen -t ed25519` if you don't have one)
- Your own public IP, for `allowed_ssh_cidr` (`curl ifconfig.me`)

## Quickstart

```bash
cd gcp
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars   # set project_id, allowed_ssh_cidr, ssh_public_key, db_password

tofu init
tofu plan
tofu apply
```

```bash
tofu output   # lb_url, node_app_url/python_app_url/php_app_url, mysql/redis endpoints
```

Note: the load balancer can take a minute or two to become fully healthy
after `apply` finishes - if a URL 404s or times out immediately, wait and
retry.

```bash
tofu destroy   # tear down when done
```

## What gets created & cost

- A custom VPC, private services access networking, and firewall rules
- 3x Compute Engine VM (`e2-micro` - the smallest size, covered by GCP's
  Always Free tier for one instance/month in `us-central1`)
- Cloud SQL for MySQL (`db-f1-micro` - the smallest tier; Cloud SQL has no
  free tier)
- Memorystore for Redis (1 GB, BASIC tier - the smallest size; Memorystore
  has no free tier)
- An external HTTP load balancer (no free tier - roughly $18+/month on its
  own)

**Estimated cost**: roughly $25-35/month - mostly Cloud SQL, Memorystore,
and the load balancer, none of which have a free tier. Run `tofu destroy`
when you're done experimenting.

## Learn more

- Architecture diagram, load balancing, and environment variables (same
  mechanism for all four providers): [root README](../README.md)
- GCP-specific details (why "private services access" is needed for
  Cloud SQL/Memorystore, the load balancer's resource chain): see the
  comments in `network.tf`, `database.tf`, `redis.tf`, and
  `loadbalancer.tf` in this folder.
