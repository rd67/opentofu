# AWS - OpenTofu starter

Provisions three tiny app VMs (Node.js, Python, PHP) behind an Application
Load Balancer, a managed MySQL database (RDS), and a managed Redis cache
(ElastiCache) on AWS. See the [root README](../README.md) for the shared
architecture diagram and how load balancing / environment variables work.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.6
- AWS credentials configured locally (`aws configure`, or
  `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` env vars)
- An SSH key pair (`ssh-keygen -t ed25519` if you don't have one)
- Your own public IP, for `allowed_ssh_cidr` (`curl ifconfig.me`)

## Quickstart

```bash
cd aws
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars   # set allowed_ssh_cidr, ssh_public_key, db_password

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

AWS has no first-class "project" container like DigitalOcean/GCP - the
closest equivalent is an **AWS Resource Group** (`project.tf`), a saved
console query that groups everything tagged `Project`/`Environment`
together under Resource Groups & Tag Editor. Purely organizational.

## What gets created & cost

- A Resource Group (groups the resources below in the console, by tag)
- A VPC, 2 subnets, security groups, and an SSH key pair
- 3x EC2 instance (`t3.micro` - AWS free-tier eligible for 12 months)
- RDS MySQL (`db.t3.micro` - free-tier eligible for 12 months)
- ElastiCache Redis (`cache.t3.micro` - free-tier eligible for 12 months)
- An Application Load Balancer (**not** free-tier eligible - roughly
  $16-20/month on its own, regardless of traffic)

**Estimated cost**: ~$16-20/month while the EC2/RDS/ElastiCache free tiers
are active (just the ALB), more after your account's 12-month free tier
window ends. Run `tofu destroy` when you're done experimenting.

## Learn more

- Architecture diagram, load balancing, and environment variables (same
  mechanism for all four providers): [root README](../README.md)
- AWS-specific details (why two subnets, the ALB's path-routing rules, the
  security group hardening): see the comments in `network.tf`,
  `loadbalancer.tf`, and `compute.tf` in this folder.
