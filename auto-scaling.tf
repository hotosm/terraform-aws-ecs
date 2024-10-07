resource "aws_appautoscaling_target" "main" {
  max_capacity = lookup(var.scaling_target_values, "container_max_count")
  min_capacity = lookup(var.scaling_target_values, "container_min_count")

  resource_id = join("/", [
    "service",
    aws_ecs_cluster.main.name,
    aws_ecs_service.main.name
  ])

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "by-req" {
  count = lookup(var.load_balancer_settings, "enabled") ? 1 : 0

  name        = "scale-by-request-count"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {

    target_value = lookup(var.load_balancer_settings, "scaling_request_count")

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = join("/", [
        lookup(var.load_balancer_settings, "arn_suffix"),
        lookup(var.load_balancer_settings, "target_group_arn_suffix")
      ])
    }
  }
}

resource "aws_appautoscaling_policy" "by-mem" {
  count = lookup(var.scale_by_memory, "enabled") ? 1 : 0

  name        = "scale-by-memory"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {

    target_value = lookup(var.scale_by_memory, "memory_pct")

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "by-cpu" {
  count = lookup(var.scale_by_cpu, "enabled") ? 1 : 0

  name        = "scale-by-cpu"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {

    target_value = lookup(var.scale_by_cpu, "cpu_pct")

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

