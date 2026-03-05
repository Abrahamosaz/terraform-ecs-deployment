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


variable "instance_type" {
  description = "Instance resource type for ec2 running the cluster"
  type        = string
  default     = "t3.micro"
}


variable "instance_max_cap" {
  description = "Max capacity for ec2"
  type        = number
  default     = 2
}

variable "instance_min_cap" {
  description = "Max capacity for ec2"
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
  }))

  default = {
    web_task = {
      image         = "nginx:latest"
      cpu           = 256
      memory        = 512
      port          = 80
      desired_count = 1
    }
  }
}
