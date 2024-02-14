variable "namespace" {}

variable "redis_server" {}
variable "redis_port" {}

variable "rds_username" {}
variable "rds_password" {}
variable "rds_host" {}
variable "rds_port" {}

variable "ebs_volume_id" {}

variable "mcp_client_container_image" {
  type = string
}

variable "mcp_server_container_image" {
  type = string
}

variable "storage_service_container_image" {
  type = string
}

variable "dashboard_container_image" {
  type = string
}

variable "nginx_container_image" {
  type = string
}

variable "clamavd_container_image" {
  type = string
}

variable "certificate_arn" {}

variable "storage_service_hostname" {}
variable "dashboard_hostname" {}

variable "ingests_bucket_arn" {}
variable "transfer_source_bucket_arn" {}
variable "transfer_source_bucket_name" {}
variable "storage_service_bucket_arn" {}

variable "archivematica_username" {}
variable "archivematica_api_key" {}
variable "archivematica_ss_username" {}
variable "archivematica_ss_api_key" {}

variable "network_private_subnets" {}
variable "network_public_subnets" {}
variable "vpc_id" {}

variable "interservice_security_group_id" {}
variable "service_egress_security_group_id" {}
variable "service_lb_security_group_id" {}

variable "admin_cidr_ingress" {
  type = list(string)
}

variable "lambda_error_alarm_arn" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "azure_tenant_id" {}
variable "oidc_client_id" {}

variable "turn_off_outside_office_hours" {
  default = true
  type    = bool
}

variable "container_host_ami" {
  description = "The AMI to use for the container host"
  type        = string
}

variable "bastion_host_ami" {
  description = "The AMI to use for the bastion host"
  type        = string
}
