variable "namespace" {}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "secret_env_vars" {
  type    = map(string)
  default = {}
}

variable "container_image" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "command" {
  type    = list(string)
  default = []
}

variable "cpu" {}

variable "memory" {}

variable "mount_points" {
  type    = list(string)
  default = []
}

variable "cluster_arn" {}
variable "namespace_id" {}

variable "network_private_subnets" {
  type = list(string)
}

variable "interservice_security_group_id" {}
variable "service_egress_security_group_id" {}
variable "service_lb_security_group_id" {}
