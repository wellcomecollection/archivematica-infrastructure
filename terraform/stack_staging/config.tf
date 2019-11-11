data "aws_ssm_parameter" "admin_cidr_ingress" {
  name = "/archivematica/config/prod/admin_cidr_ingress"
}

locals {
  admin_cidr_ingress = "${split(",", data.aws_ssm_parameter.admin_cidr_ingress.value)}"
}
