variable "namespace" {}

variable "network_private_subnets" {}
variable "network_public_subnets" {}
variable "vpc_id" {}

variable "admin_cidr_ingress" {
  type = "list"
}

variable "efs_id" {}
variable "efs_security_group_id" {}

variable "aws_region" {
  default = "eu-west-1"
}
