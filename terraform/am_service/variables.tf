variable "name" {}

variable "env_vars" {
  type = "map"
}
variable "env_vars_length" {}

variable "container_image" {}

variable "aws_region" {
  default = "eu-west-1"
}

variable "cpu" {
  default = 256
}

variable "memory" {
  default = 512
}

variable "mount_points" {
  type = "list"
}

variable "cluster_id" {}
variable "namespace_id" {}
