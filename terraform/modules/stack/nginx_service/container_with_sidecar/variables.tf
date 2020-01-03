variable "task_name" {}

variable "cpu" {}
variable "memory" {}

# App

variable "app_container_image" {}
variable "app_container_port" {
  default = ""
}
variable "app_container_name" {
  default = "app"
}
variable "app_cpu" {}
variable "app_memory" {}

variable "app_mount_points" {
  type    = list(map(string))
  default = []
}

variable "app_env_vars" {
  type    = map(string)
  default = {}
}

variable "secret_app_env_vars" {
  type    = map(string)
  default = {}
}

# Sidecar

variable "sidecar_container_image" {}
variable "sidecar_container_port" {}
variable "sidecar_container_name" {
  default = "nginx"
}
variable "sidecar_cpu" {}
variable "sidecar_memory" {}

variable "sidecar_env_vars" {
  type    = map(string)
  default = {}
}

variable "secret_sidecar_env_vars" {
  type    = map(string)
  default = {}
}

variable "app_user" {
  default = "root"
}

variable "sidecar_user" {
  default = "root"
}

variable "launch_type" {
  default = "FARGATE"
}

variable "aws_region" {}
