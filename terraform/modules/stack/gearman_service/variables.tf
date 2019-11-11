variable "namespace" {}

variable "env_vars" {
  type    = "map"
  default = {}
}

variable "secret_env_vars" {
  type    = "map"
  default = {}
}

variable "container_image" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "command" {
  type    = "list"
  default = []
}

variable "cpu" {
  default = 512
}

variable "memory" {
  default = 1024
}

variable "mount_points" {
  type    = "list"
  default = []
}

variable "cluster_arn" {}
variable "namespace_id" {}

variable "network_private_subnets" {
  type = "list"
}

variable "interservice_security_group_id" {}
variable "service_egress_security_group_id" {}
variable "service_lb_security_group_id" {}
