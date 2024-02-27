resource "aws_appautoscaling_target" "main" {
  max_capacity = lookup(var.scaling_target_values, "container_max_count")
  min_capacity = lookup(var.scaling_target_values, "container_min_count")

  resource_id = join("/", [
    "service",
    var.ecs_cluster_name,
    aws_ecs_service.main.name
  ])

  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "by-req" {
  name        = "scale-by-request-count"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {

    target_value = lookup(var.scaling_target_values, "request_count")

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = join("/", [
        var.load_balancer_arn_suffix,
        var.target_group_arn_suffix
      ])
    }
  }
}

resource "aws_appautoscaling_policy" "by-mem" {
  name        = "scale-by-memory"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {

    target_value = lookup(var.scaling_target_values, "memory_pct")

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "by-cpu" {
  name        = "scale-by-cpu"
  policy_type = "TargetTrackingScaling"

  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  target_tracking_scaling_policy_configuration {

    target_value = lookup(var.scaling_target_values, "cpu_pct")

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

