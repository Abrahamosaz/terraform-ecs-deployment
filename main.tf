
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr_block             = var.vpc_cidr_block
  public_subnet_cidr_blocks  = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks
  resource_tags              = var.resource_tags
  region                     = var.region
  availability_zones         = var.azs
  enable_ngw                 = true
}


module "ecs" {
  source = "./modules/ecs"

  cluster_name = "${var.resource_tags["Project"]}-cluster"

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  resource_tags      = var.resource_tags
  region             = var.region
  availability_zones = var.azs

  instance_details = {
    instance_type = "t3.micro"
    ami           = ""
  }

  services = {
    web_task = {
      image         = "nginx:latest"
      cpu           = 256
      memory        = 512
      port          = 80
      desired_count = 1
      health_check  = "/"
    }
  }
}
