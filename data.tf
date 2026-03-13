data "aws_secretsmanager_secret" "db_credentials" {
  region = var.region
  name   = "rds-credentials"
}
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}


locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}
