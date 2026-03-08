variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet ids"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet ids"
  type        = list(string)
}

variable "availability_zones" {
  description = "Multi AZ for high availability, it should match the number of subnets (both private and public)"
  type        = list(string)
}

variable "resource_tags" {
  description = "ECS resource tags"
  type        = map(string)
}

variable "region" {
  description = "Region for ECS cluster"
  type        = string
}

variable "cluster_name" {
  description = "Cluster Name"
  type        = string
}

variable "instance_details" {
  description = "Instance resource types for EC2 running the cluster"
  type = object({
    instance_type = string
    ami           = string
  })

  default = {
    instance_type = "t3.micro"
    ami           = ""
  }
}

variable "min_ec2_desired_capacity_for_asg" {
  description = "Min ec2 desired instance for asg for ecs"
  type        = number
  default     = 1
}

variable "max_ec2_desired_capacity_for_asg" {
  description = "Max ec2 desired instance for asg for ecs"
  type        = number
  default     = 2
}

variable "services" {
  description = "Services to run on ECS cluster. Maps a logical service name to its container config."
  type = map(object({
    image         = string
    cpu           = number
    memory        = number
    port          = number
    desired_count = number
    health_check  = string
  }))
}
