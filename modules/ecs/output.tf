output "alb_dns" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}
