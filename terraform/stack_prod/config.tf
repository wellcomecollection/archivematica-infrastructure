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

data "aws_ssm_parameter" "azure_tenant_id" {
  name = "/archivematica/config/prod/azure_tenant_id"
}

data "aws_ssm_parameter" "oidc_client_id" {
  name = "/archivematica/config/prod/oidc_client_id"
}

locals {
  admin_cidr_ingress = split(",", data.aws_ssm_parameter.admin_cidr_ingress.value)

  archivematica_username    = data.aws_ssm_parameter.archivematica_username.value
  archivematica_api_key     = data.aws_ssm_parameter.archivematica_api_key.value
  archivematica_ss_username = data.aws_ssm_parameter.archivematica_ss_username.value
  archivematica_ss_api_key  = data.aws_ssm_parameter.archivematica_ss_api_key.value
  azure_tenant_id           = data.aws_ssm_parameter.azure_tenant_id.value
  oidc_client_id            = data.aws_ssm_parameter.oidc_client_id.value
}
