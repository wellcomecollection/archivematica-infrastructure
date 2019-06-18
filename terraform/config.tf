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

data "aws_ssm_parameter" "archivematica_username" {
  name = "/archivematica/config/prod/archivematica_username"
}

data "aws_ssm_parameter" "archivematica_api_key" {
  name = "/archivematica/config/prod/archivematica_api_key"
}

data "aws_ssm_parameter" "archivematica_ss_username" {
  name = "/archivematica/config/prod/archivematica_ss_username"
}

data "aws_ssm_parameter" "archivematica_ss_api_key" {
  name = "/archivematica/config/prod/archivematica_ss_api_key"
}

locals {
  rds_username       = "${data.aws_ssm_parameter.rds_username.value}"
  rds_password       = "${data.aws_ssm_parameter.rds_password.value}"
  elasticsearch_url  = "${data.aws_ssm_parameter.elasticsearch_url.value}"
  admin_cidr_ingress = "${split(",", data.aws_ssm_parameter.admin_cidr_ingress.value)}"
  archivematica_username = "${data.aws_ssm_parameter.archivematica_username.value}"
  archivematica_api_key = "${data.aws_ssm_parameter.archivematica_api_key.value}"
  archivematica_ss_username = "${data.aws_ssm_parameter.archivematica_ss_username.value}"
  archivematica_ss_api_key = "${data.aws_ssm_parameter.archivematica_ss_api_key.value}"
}
