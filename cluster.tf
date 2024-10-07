resource "aws_ecs_cluster" "main" {
  name = "${lookup(var.project_meta, "name")}-${var.deployment_environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.default_tags
}