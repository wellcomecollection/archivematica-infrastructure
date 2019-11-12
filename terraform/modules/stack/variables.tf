variable "namespace" {}

variable "efs_id" {}
variable "efs_security_group_id" {}

variable "redis_server" {}
variable "redis_port" {}

variable "rds_username" {}
variable "rds_password" {}
variable "rds_host" {}
variable "rds_port" {}

variable "mcp_client_container_image" {}
variable "mcp_server_container_image" {}
variable "storage_service_container_image" {}
variable "storage_service_nginx_container_image" {}
variable "dashboard_container_image" {}
variable "dashboard_nginx_container_image" {}

variable "certificate_arn" {}

variable "storage_service_hostname" {}
variable "dashboard_hostname" {}

variable "network_private_subnets" {}
variable "network_public_subnets" {}
variable "vpc_id" {}

variable "interservice_security_group_id" {}
variable "service_egress_security_group_id" {}
variable "service_lb_security_group_id" {}

variable "admin_cidr_ingress" {
  type = "list"
}

variable "lambda_error_alarm_arn" {}

variable "aws_region" {
  default = "eu-west-1"
}
