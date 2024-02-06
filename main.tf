resource "aws_ecs_cluster" "main" {
  name = lookup(var.project_meta, "project")

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = lookup(var.project_meta, "project")
  }
}


resource "aws_ecs_service" "main" {
  name            = lookup(var.project_meta, "project")
  cluster         = aws_ecs_cluster.main.arn
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
  health_check_grace_period_seconds = 400

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = lookup(var.alb_settings, "container_name")
    container_port   = lookup(var.container_settings, "app_port")
  }

  network_configuration {
    subnets          = lookup(var.service_settings, "subnets")
    security_groups  = lookup(var.service_settings, "security_groups")
    assign_public_ip = false
  }

  propagate_tags = var.propagate_tags_from

  /**
  service_connect_configuration {
    enabled = true
    log_configuration {
      log_driver = "syslog"
      options    = {}
      secret_option {
        name       = ""
        value_from = ""
      }
    }
    namespace = ""
    service {
      client_alias {
        dns_name = ""
        port     = lookup(var.container_settings, "app_port)
      }
      discovery_name        = ""
      ingress_port_override = lookup(var.container_settings, "app_port)
      port_name             = ""
    }
  }

  service_registries {
    registry_arn   = ""
    port           = lookup(var.container_settings, "app_port)
    container_port = lookup(var.container_settings, "app_port)
    container_name = ""
  }
  **/

  force_new_deployment = true

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  triggers = {
    redeployment = plantimestamp()
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
