variable "name" {}

variable "env_vars" {
  type    = "map"
  default = {}
}

variable "env_vars_length" {
  default = 0
}

variable "secret_env_vars" {
  type    = "map"
  default = {}
}

variable "secret_env_vars_length" {
  default = 0
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
  type    = "list"
  default = []
}

variable "cluster_id" {}
variable "namespace_id" {}
