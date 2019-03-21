variable "name" {}

variable "env_vars" {
  type    = "map"
  default = {}
}
variable "env_vars_length" {
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
  default = 1024
}

variable "memory" {
  default = 1536
}

variable "mount_points" {
  type    = "list"
  default = []
}

variable "cluster_id" {}
variable "namespace_id" {}
