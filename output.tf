output "ec2_instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.demo_ec2_instance.public_ip
}

output "ec2_instance_url" {
  description = "URL to access Nginx on the EC2 instance"
  value       = "http://${aws_instance.demo_ec2_instance.public_ip}"
}
