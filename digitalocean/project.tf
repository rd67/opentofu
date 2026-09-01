# Groups this stack's resources into a named DigitalOcean Project, so they
# show up together in the console instead of mixed in with everything else
# in "My Team" (or whichever team the token belongs to). Projects are a
# purely organizational feature - they don't affect networking, billing
# scope, or access control.
resource "digitalocean_project" "main" {
  name        = var.project_name
  description = "OpenTofu starter - Node.js/Python/PHP apps behind a load balancer, managed MySQL, managed Valkey (${var.environment})"
  purpose     = "Web Application"
  environment = lookup(
    { dev = "Development", staging = "Staging", prod = "Production", production = "Production" },
    lower(var.environment),
    "Development"
  )
}

# Only droplets, database clusters, and load balancers are project-assignable
# resource types here - the VPC itself isn't.
resource "digitalocean_project_resources" "main" {
  project = digitalocean_project.main.id
  resources = concat(
    [for d in digitalocean_droplet.app : d.urn],
    [
      digitalocean_droplet.edge.urn,
      digitalocean_database_cluster.mysql.urn,
      digitalocean_database_cluster.redis.urn,
      digitalocean_loadbalancer.main.urn,
    ]
  )
}
