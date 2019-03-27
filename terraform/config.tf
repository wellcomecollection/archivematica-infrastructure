data "aws_ssm_parameter" "elasticsearch_url" {
  name = "/archivematica/config/prod/elasticsearch_url"
}

data "aws_ssm_parameter" "rds_username" {
  name = "/archivematica/config/prod/rds_username"
}

data "aws_ssm_parameter" "rds_password" {
  name = "/archivematica/config/prod/rds_password"
}

data "aws_ssm_parameter" "admin_cidr_ingress" {
  name = "/archivematica/config/prod/admin_cidr_ingress"
}

locals {
  rds_username       = "${data.aws_ssm_parameter.rds_username.value}"
  rds_password       = "${data.aws_ssm_parameter.rds_password.value}"
  elasticsearch_url  = "${data.aws_ssm_parameter.elasticsearch_url.value}"
  admin_cidr_ingress = "${split(",", data.aws_ssm_parameter.admin_cidr_ingress.value)}"
}
