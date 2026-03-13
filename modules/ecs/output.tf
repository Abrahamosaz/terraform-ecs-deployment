output "alb_dns" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "ecs_tasks_sg_id" {
  description = "Security group ID used by ECS tasks"
  value       = aws_security_group.ecs_tasks_sg.id
}
