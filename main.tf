resource "aws_ecs_service" "main" {
  name            = var.service_name
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.main.arn

  dynamic "alarms" {
    for_each = lookup(var.alarm_settings, "enable") ? lookup(var.alarm_settings, "names") : []

    content {
      alarm_names = lookup(var.alarm_settings, "names")
      enable      = lookup(var.alarm_settings, "enable")
      rollback    = lookup(var.alarm_settings, "rollback")
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = var.deployment_controller
  }

  desired_count                      = lookup(var.tasks_count, "desired_count")
  deployment_maximum_percent         = lookup(var.tasks_count, "max_pct")
  deployment_minimum_healthy_percent = lookup(var.tasks_count, "min_healthy_pct")

  enable_ecs_managed_tags           = true
  health_check_grace_period_seconds = lookup(var.load_balancer_settings, "enabled") ? 400 : null

  launch_type = "FARGATE"

  dynamic "load_balancer" {
    for_each = lookup(var.load_balancer_settings, "enabled") ? ["a"] : []

    content {
      target_group_arn = lookup(var.load_balancer_settings, "target_group_arn")
      container_name   = lookup(var.container_settings, "service_name")
      container_port   = lookup(var.container_settings, "app_port")
    }
  }

  network_configuration {
    subnets          = var.service_subnets
    security_groups  = concat(var.service_security_groups)
    assign_public_ip = false
  }

  propagate_tags = var.propagate_tags_from

  force_new_deployment = var.force_new_deployment

  triggers = {
    redeployment = plantimestamp()
  }

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }
}
