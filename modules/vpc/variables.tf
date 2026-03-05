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
}

variable "availability_zones" {
  description = "Multi AZ for high availability, it should match the number of subnets (both private and public)"
  type        = list(string)
}


variable "enable_ngw" {
  description = "Boolean to control if a nat gateway should be created for private subnet"
  type        = bool
  default     = false
}
