resource "aws_ecs_task_definition" "main" {
  family                   = lookup(var.container_settings, "service_name")
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = lookup(var.container_settings, "cpu_architecture")
  }

  volume {
    name = "efs-volume"

    efs_volume_configuration {
      file_system_id          = lookup(var.efs_settings, "file_system_id")
      root_directory          = lookup(var.efs_settings, "root_directory")
      transit_encryption      = lookup(var.efs_settings, "transit_encryption")
      transit_encryption_port = lookup(var.efs_settings, "transit_encryption_port")

      authorization_config {
        access_point_id = lookup(var.efs_settings, "access_point_id")
        iam             = lookup(var.efs_settings, "iam_authz")
      }

    }
  }

  container_definitions = jsonencode([
    {
      name = "main" // PARAMETERIZE
      image = join(":", [
        lookup(var.container_settings, "image_url"),
        lookup(var.container_settings, "image_tag")
      ])

      privileged = lookup(var.container_security, "privileged")

      cpu       = lookup(var.container_capacity, "cpu")
      memory    = lookup(var.container_capacity, "memory_mb")
      essential = true

      portMappings = [
        {
          containerPort = lookup(var.container_settings, "app_port")
          hostPort      = lookup(var.container_settings, "app_port")
        },
      ]

      environment = var.container_envvars
      secrets     = var.container_secrets

      linuxParameters = {
        capabilities = var.linux_capabilities
      }

      logConfiguration = var.log_configuration
    }
  ])
}

