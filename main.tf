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

  desired_count                      = var.tasks_desired_count
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = var.tasks_desired_count >= 2 ? 50 : 100

  enable_ecs_managed_tags           = true
  health_check_grace_period_seconds = 400

  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = var.alb_target_group
    container_name   = var.alb_container_name
    container_port   = var.alb_container_port
  }

  network_configuration {
    subnets         = var.service_subnets
    security_groups = var.service_security_groups
  }

  propagate_tags = var.propagate_tags_from // "TASK_DEFINITION" or "SERVICE"

  /**
  service_connect_configuration {
    enabled = true
    log_configuration {
      log_driver = "syslog" // json-file, journald, gelf, fluentd, awslogs, splunk, awsfirelens
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
        port     = 8000 // Must be number
      }
      discovery_name        = ""
      ingress_port_override = 8000 // Must be number
      port_name             = ""
    }
  }

  service_registries {
    registry_arn   = ""
    port           = 8000 // Must be number
    container_port = 8000 // Must be number
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
}
