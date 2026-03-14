provider "aws" {
  profile = "default"
  region  = var.region
}

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
    frontend = {
      image         = "abrahamosaz/ecs-project-frontend:linux"
      cpu           = 256
      memory        = 512
      port          = 80
      desired_count = 1
      health_check  = "/"
      environment = {
        BACKEND_URL = "http://${module.ecs.alb_dns}/backend"
      }
    },
    backend = {
      image         = "abrahamosaz/ecs-project-backend:linux"
      cpu           = 256
      memory        = 512
      port          = 4000
      desired_count = 1
      health_check  = "/health"
      environment = {
        MYSQL_HOST     = module.mysql.db_endpoint
        MYSQL_USER     = local.db_credentials["db_username"]
        MYSQL_PASSWORD = local.db_credentials["db_password"]
        MYSQL_DATABASE = module.mysql.db_name
      }
    }
  }
}


module "mysql" {
  source = "./modules/rds"

  region   = var.region
  db_name  = var.db_name
  username = local.db_credentials["db_username"]
  password = local.db_credentials["db_password"]

  resource_tags          = var.resource_tags
  db_subnet_ids          = module.vpc.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_security_group" "db_sg" {
  name        = "${var.resource_tags["Project"]}-db-sg"
  description = "Allow ECS tasks to connect to RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.ecs.ecs_tasks_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.resource_tags
}
