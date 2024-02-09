output "cluster_arn" {
  value       = aws_ecs_service.main.cluster
  description = "Cluster ARN associated to the service"
}

output "desired_count" {
  value       = aws_ecs_service.main.desired_count
  description = "Number of instances of the task definition"
}

output "service_arn" {
  value       = aws_ecs_service.main.id
  description = "ARN that identifies the service"
}

output "service_name" {
  value       = aws_ecs_service.main.name
  description = "Name of the service"
}

output "load_balancer" {
  description = "ARN of the application load balancer"
  value       = aws_lb.public.arn
}

output "load_balancer_security_group" {
  description = "ID of the load balancer security group"
  value       = aws_security_group.alb.id
}

output "target_group" {
  description = "ARN of the load balancer target group"
  value       = aws_lb_target_group.main.arn
}

output "service_security_group" {
  description = "ID of the service security group"
  value       = aws_security_group.svc.id
}

output "task_definition" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

