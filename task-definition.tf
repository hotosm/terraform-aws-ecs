resource "aws_ecs_task_definition" "main" {
  family                   = lookup(var.container_settings, "service_name")
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = lookup(var.container_capacity, "cpu")
  memory                   = lookup(var.container_capacity, "memory_mb")
  ephemeral_storage        = var.container_ephemeral_storage

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.container_cpu_architecture
  }

  dynamic "volume" {
    for_each = var.efs_enabled ? ["a"] : []

    content {
      name = "efs-volume"

      efs_volume_configuration {
        file_system_id     = lookup(var.efs_settings, "file_system_id")
        root_directory     = lookup(var.efs_settings, "root_directory")
        transit_encryption = lookup(var.efs_settings, "transit_encryption")

        authorization_config {
          access_point_id = lookup(var.efs_settings, "access_point_id")
          iam             = lookup(var.efs_settings, "iam_authz")
        }
      }
    }
  }

  container_definitions = jsonencode([
    {
      name = lookup(var.container_settings, "service_name")

      image = join(":", [
        lookup(var.container_settings, "image_url"),
        lookup(var.container_settings, "image_tag")
      ])
      command = var.container_commands

      privileged = lookup(var.container_security, "privileged")

      cpu       = lookup(var.container_capacity, "cpu")
      memory    = lookup(var.container_capacity, "memory_mb")
      essential = true

      portMappings = [
        {
          containerPort = lookup(var.container_settings, "app_port")
          hostPort      = lookup(var.container_settings, "app_port")
          protocol      = var.app_port_protocol
        },
      ]

      environment = var.container_envvars
      secrets     = var.container_secrets

      mountPoints = var.efs_enabled ? [
        {
          containerPath = var.container_efs_volume_mount_path
          readOnly      = false
          sourceVolume  = "efs-volume"
        }
      ] : null

      linuxParameters = {
        capabilities = var.linux_capabilities
      }

      logConfiguration = var.log_configuration
    }
  ])

  execution_role_arn = aws_iam_role.ecs-agent.arn
  task_role_arn      = var.task_role_arn
}

