data "aws_caller_identity" "current" {}

data "aws_iam_user" "Abraham" {
  user_name = "Abraham"
}
