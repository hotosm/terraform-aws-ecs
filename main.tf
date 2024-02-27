resource "aws_security_group" "egress-only" {
  name_prefix = "egress-only"
  description = "Egress only security group"
  vpc_id      = var.aws_vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}


resource "aws_security_group" "svc" {
  name_prefix = "svc_private_access"
  description = "Private access to service from load balancer"
  vpc_id      = var.aws_vpc_id

  ingress {
    description     = "Allow connections from load balancer"
    from_port       = lookup(var.container_settings, "app_port")
    to_port         = lookup(var.container_settings, "app_port")
    protocol        = "tcp"
    security_groups = var.load_balancer_enabled ? [aws_security_group.alb.id] : [aws_security_group.egress-only.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "all"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_service" "main" {
  name            = lookup(var.project_meta, "name")
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
  health_check_grace_period_seconds = 400

  launch_type = "FARGATE"

  dynamic "load_balancer" {
    for_each = var.load_balancer_enabled ? ["a"] : []

    content {
      target_group_arn = aws_lb_target_group.main.arn
      container_name   = lookup(var.container_settings, "service_name")
      container_port   = lookup(var.container_settings, "app_port")
    }
  }

  network_configuration {
    subnets          = lookup(var.service_settings, "subnets")
    security_groups  = concat(var.service_security_groups, [aws_security_group.svc.id])
    assign_public_ip = false
  }

  propagate_tags = lookup(var.service_settings, "propagate_tags_from")

  force_new_deployment = true

  triggers = {
    redeployment = plantimestamp()
  }

  lifecycle {
    ignore_changes = [
      desired_count
    ]
  }
}
