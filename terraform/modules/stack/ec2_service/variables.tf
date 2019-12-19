variable "namespace" {}
variable "name" {}

variable "cluster_arn" {}
variable "namespace_id" {}

variable "cpu" {}

variable "memory" {}

variable "env_vars" {
  type    = map(string)
  default = {}
}

variable "secret_env_vars" {
  type    = map(string)
  default = {}
}

variable "container_image" {}

variable "mount_points" {
  type = list(map(string))
}

variable "desired_task_count" {
  default = 1
}

variable "network_private_subnets" {
  type = list(string)
}

variable "interservice_security_group_id" {}
variable "service_egress_security_group_id" {}
variable "service_lb_security_group_id" {}
