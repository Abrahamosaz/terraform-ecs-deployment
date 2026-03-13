variable "region" {
  description = "region"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "username" {
  description = "Database username"
  type        = string
}

variable "password" {
  description = "Database password"
  type        = string
}

variable "db_subnet_ids" {
  description = "Subnet IDs for the RDS subnet group (must belong to the target VPC)"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs to associate with the RDS instance"
  type        = list(string)
}

variable "resource_tags" {
  description = "Tags for this project resources"
  type        = map(string)
}

variable "storage" {
  description = "Size of allocation for the database in GB"
  type        = number
  default     = 10
}

variable "engine" {
  description = "Engine of the rds to use e.g (mysql, postgresql)"
  type        = string
  default     = "mysql"
}

variable "instance_class" {
  description = "Class of instance type for db"
  type        = string
  default     = "db.t3.micro"
}
