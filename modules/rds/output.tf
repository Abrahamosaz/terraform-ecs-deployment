output "db_endpoint" {
  description = "Endpoint address of the RDS instance"
  value       = aws_db_instance.rds.address
}

output "db_port" {
  description = "Port on which the RDS instance is listening"
  value       = aws_db_instance.rds.port
}

output "db_name" {
  description = "Name of the database created in the RDS instance"
  value       = aws_db_instance.rds.db_name
}

output "db_username" {
  description = "Master username for the RDS instance"
  value       = aws_db_instance.rds.username
  sensitive   = true
}

output "db_connection_url" {
  description = "Full database connection URL built from engine, credentials, endpoint, and database name"
  value       = format("%s://%s:%s@%s:%s/%s", var.engine, var.username, var.password, aws_db_instance.rds.address, aws_db_instance.rds.port, var.db_name)
  sensitive   = true
}
