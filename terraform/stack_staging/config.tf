data "aws_ssm_parameter" "elasticsearch_url" {
  name = "/archivematica/config/prod/elasticsearch_url"
}

data "aws_ssm_parameter" "admin_cidr_ingress" {
  name = "/archivematica/config/prod/admin_cidr_ingress"
}

locals {
  admin_cidr_ingress = "${split(",", data.aws_ssm_parameter.admin_cidr_ingress.value)}"

  elasticsearch_url = data.aws_ssm_parameter.elasticsearch_url.value
}
