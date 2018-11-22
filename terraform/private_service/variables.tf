variable "aws_region" {}
variable "name" {}
variable "cpu" {}
variable "memory" {}
variable "log_group_prefix" {}

variable "container_image" {}
variable "container_port" {}

variable "env_vars" {
  type = "map"
}

variable "ebs_container_path" {}
variable "ebs_host_path" {}

variable "task_desired_count" {
  default = "1"
}

variable "lb_arn" {}
variable "healthcheck_path" {}
variable "namespace_id" {}

variable "private_subnets" {
  type = "list"
}

variable "vpc_id" {}
variable "cluster_id" {}

variable "security_group_ids" {
  type = "list"
}

variable "env_vars_length" {}
