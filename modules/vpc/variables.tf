variable "name" {
    type = string
}

variable "eks_cluster_name" {
    type = string
    description = "Name of the EKS cluster"
    default     = "default-eks-cluster"
}

variable "env" {
    type = string
    default = "dev"
}

variable "cidr_block" {
    type = string
}

variable "region" {
    type = string
}

variable "azs" {
    
    type = list(string)
    description = "List of exactly two Availability Zones"
    validation {
        condition     = length(var.azs) == 2
        error_message = "Exactly two availability zones must be provided."
    }
}

variable "no_of_public_subnets" {
    type = number
    default = 2
}

variable "no_of_private_subnets" {
    type = number
    default = 2
}

variable "public_routes_cidr_blocks" {
    type = list(string)
    default = ["0.0.0.0/0"]
}

variable "private_routes_cidr_blocks" {
    type = list(string)
    default = ["0.0.0.0/0"]
}