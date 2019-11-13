data "aws_ssm_parameter" "rds_username" {
  name = "/archivematica/config/prod/rds_username"
}

data "aws_ssm_parameter" "rds_password" {
  name = "/archivematica/config/prod/rds_password"
}

locals {
  rds_username = data.aws_ssm_parameter.rds_username.value
  rds_password = data.aws_ssm_parameter.rds_password.value
}
