variable "namespace" {}

variable "cluster_arn" {}
variable "namespace_id" {}

variable "cpu" {
  default = 2048
}

variable "memory" {
  default = 3072
}

variable "container_image" {}

variable "mount_points" {
  type = list(map(string))
}

variable "network_private_subnets" {
  type = list(string)
}

variable "interservice_security_group_id" {}
variable "service_egress_security_group_id" {}
variable "service_lb_security_group_id" {}
