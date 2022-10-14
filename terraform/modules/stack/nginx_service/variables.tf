variable "namespace" {
  type = string
}
variable "name" {
  type = string
}
variable "cluster_arn" {
  type = string
}
variable "cpu" {
  type = number
}
variable "memory" {
  type = number
}

variable "app_container_image" {}
variable "nginx_container_image" {}

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
  type    = number
  default = 100
}

variable "deployment_maximum_percent" {
  type    = number
  default = 200
}

variable "load_balancer_https_listener_arn" {
  type = string
}

variable "healthcheck_path" {}
variable "healthcheck_timeout" {
  type    = number
  default = 5
}

variable "vpc_id" {
  type = string
}

variable "hostname" {
  type = string
}
