variable "namespace" {}
variable "name" {}

variable "cluster_arn" {}

variable "cpu" {}
variable "memory" {}

variable "container_image" {}

variable "mount_points" {
  type = list(object({
    containerPath = string
    sourceVolume  = string
  }))

  default = []
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

variable "secrets" {
  type    = map(string)
  default = {}
}

variable "environment" {
  type    = map(string)
  default = {}
}

variable "namespace_id" {
  type = string
}

variable "deployment_minimum_healthy_percent" {
  type = number
}

variable "deployment_maximum_percent" {
  type = number
}