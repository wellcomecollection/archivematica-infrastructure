variable "name" {}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "secret_env_vars" {
  type    = map(string)
  default = {}
}

variable "load_balancer_https_listener_arn" {}

variable "healthcheck_path" {}
variable "hostname" {}

variable "container_image" {}
variable "nginx_container_image" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "cpu" {
  default = 640 # 768 - 128 for the sidecar
}

variable "memory" {
  default = 1024
}

variable "mount_points" {
  type    = list(map(string))
  default = []
}

variable "cluster_arn" {}
variable "namespace_id" {}

variable "vpc_id" {}

variable "network_private_subnets" {
  type = list(string)
}

variable "interservice_security_group_id" {}
variable "service_egress_security_group_id" {}
variable "service_lb_security_group_id" {}
