# AWS has no first-class "project" container the way DigitalOcean/GCP do.
# The closest equivalent is an AWS Resource Group: a saved, dynamic query
# over your account's resources by tag, shown together in the console under
# Resource Groups & Tag Editor. It's purely organizational - it doesn't
# change networking, billing scope, or access control, and it doesn't "own"
# the resources (nothing here needs to be created before/after it).
resource "aws_resourcegroups_group" "main" {
  name        = "${var.project_name}-${var.environment}"
  description = "OpenTofu starter - Node.js/Python/PHP apps behind an ALB, RDS MySQL, ElastiCache Redis"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        { Key = "Project", Values = [var.project_name] },
        { Key = "Environment", Values = [var.environment] },
      ]
    })
  }

  tags = local.common_tags
}
