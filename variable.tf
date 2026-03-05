variable "vpc_cidr_block" {
  description = "CIDR range for vpc"
  type        = string
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
}

variable "resource_tags" {
  description = "Tags for this project resources"
  type        = map(string)
}

variable "region" {
  description = "Region for deploying resources"
  type        = string
  default     = "us-east-1"
}


variable "azs" {
  description = "Availability Zone to deploy my application"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
