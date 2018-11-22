variable "aws_region" {}
variable "name" {}
variable "cpu" {}
variable "memory" {}
variable "log_group_prefix" {}

variable "app_container_image" {}
variable "app_container_port" {}
variable "app_cpu" {}
variable "app_memory" {}

variable "app_env_vars" {
  type = "map"
}

variable "sidecar_container_image" {}
variable "sidecar_container_port" {}
variable "sidecar_cpu" {}
variable "sidecar_memory" {}
variable "ebs_container_path" {}
variable "ebs_host_path" {}

variable "sidecar_env_vars" {
  type = "map"
}

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
