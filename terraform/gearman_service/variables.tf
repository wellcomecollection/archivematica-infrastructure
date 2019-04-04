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

variable "cluster_id" {}
variable "namespace_id" {}
