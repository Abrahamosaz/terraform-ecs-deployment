resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = var.resource_tags
}

resource "aws_db_instance" "rds" {
  allocated_storage      = var.storage
  db_name                = var.db_name
  engine                 = var.engine
  engine_version         = data.aws_rds_engine_version.selected.version
  instance_class         = var.instance_class
  multi_az               = var.enable_multiaz
  username               = var.username
  password               = var.password
  storage_encrypted      = var.enable_encryption
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = var.vpc_security_group_ids


  tags = var.resource_tags
}
