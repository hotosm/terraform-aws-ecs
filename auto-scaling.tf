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

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1  # Trigger after just one period
  period              = 60 # Evaluate every 60 seconds
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = 70 # Trigger when CPU > 70%
  alarm_description   = "Alarm when CPU exceeds 70%"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }
  alarm_actions = [aws_appautoscaling_policy.scale_up_by_cpu.arn]
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "HighMemoryUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = 75 # Trigger when memory > 75%
  alarm_description   = "Alarm when memory utilization exceeds 75%"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up_by_memory.arn]
}

resource "aws_cloudwatch_metric_alarm" "memory_high_down" {
  alarm_name          = "HighMemoryUtilizationDown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  period              = 120
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = 30 # Trigger when memory < 40%
  alarm_description   = "Alarm when memory utilization exceeds 40%"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down_by_memory_down.arn]
}

resource "aws_cloudwatch_metric_alarm" "request_count_high" {
  alarm_name          = "HighRequestCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 30
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "Alarm when the average request count exceeds 150 per target add 1 unit."
  dimensions = {
    LoadBalancer = lookup(var.load_balancer_settings, "arn_suffix")
    TargetGroup  = lookup(var.load_balancer_settings, "target_group_arn_suffix")
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up_by_requests.arn]
}

resource "aws_cloudwatch_metric_alarm" "request_count_super_high" {
  alarm_name          = "SuperHighRequestCount"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 30
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  threshold           = 500
  alarm_description   = "Alarm when the average request count exceeds 1000 per target add 2 unit."
  dimensions = {
    LoadBalancer = lookup(var.load_balancer_settings, "arn_suffix")
    TargetGroup  = lookup(var.load_balancer_settings, "target_group_arn_suffix")
  }

  alarm_actions = [aws_appautoscaling_policy.scale_up_by_large_requests.arn]
}

resource "aws_cloudwatch_metric_alarm" "request_count_super_high_down" {
  alarm_name          = "SuperHighRequestCountDown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 60
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Sum"
  threshold           = 50
  alarm_description   = "Alarm when the average request count exceeds 1000 per target add 2 unit."
  dimensions = {
    LoadBalancer = lookup(var.load_balancer_settings, "arn_suffix")
    TargetGroup  = lookup(var.load_balancer_settings, "target_group_arn_suffix")
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down_by_large_requests_down.arn]
}
################################################################



resource "aws_appautoscaling_policy" "scale_up_by_memory" {
  name               = "scale-up-by-memory"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 60
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1 # Increase by 1 task
    }
  }
}


resource "aws_appautoscaling_policy" "scale_up_by_cpu" {
  name               = "scale-up-by-cpu"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average" # Set the metric aggregation type
    cooldown                = 10
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down_by_memory_down" {
  name               = "scale-down-by-memory-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 120
    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 40
      scaling_adjustment          = -1
    }
    # New Step (Handle cases above 40%)
    step_adjustment {
      metric_interval_lower_bound = 40
      scaling_adjustment          = 0
      # No scaling if memory is above 40%
    }
  }
}

resource "aws_appautoscaling_policy" "scale_up_by_requests" {
  name               = "scale-up-by-requests"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 60
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1 # Increase by 2 tasks
    }
  }
}

resource "aws_appautoscaling_policy" "scale_up_by_large_requests" {
  name               = "scale-up-by-large-requests"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 120
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 2 # Increase by 2 tasks
    }
  }
}

resource "aws_appautoscaling_policy" "scale_down_by_large_requests_down" {
  name               = "scale-by-large-requests_down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.main.resource_id
  scalable_dimension = aws_appautoscaling_target.main.scalable_dimension
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    cooldown                = 60

    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 100 # When request count is between 0 and 100
      scaling_adjustment          = -2  # Decrease by 2 tasks
    }
    step_adjustment {
      metric_interval_lower_bound = 100
      scaling_adjustment          = 0
      # No scaling if request count is above 100
    }
  }
}
