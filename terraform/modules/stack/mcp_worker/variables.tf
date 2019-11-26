variable "namespace" {}

variable "cluster_arn" {}
variable "namespace_id" {}

variable "fits_cpu" {
  default = 768
}

variable "fits_memory" {
  default = 1024
}

variable "fits_container_image" {}

variable "fits_mount_points" {
  type = list(map(string))
}

variable "clamav_cpu" {
  default = 1024
}

variable "clamav_memory" {
  default = 1536
}

variable "clamav_container_image" {}

variable "clamav_mount_points" {
  type = list(map(string))
}

variable "mcp_client_cpu" {
  default = 512
}

variable "mcp_client_memory" {
  default = 1024
}

variable "mcp_client_container_image" {}

variable "mcp_client_mount_points" {
  type = list(map(string))
}

variable "mcp_client_env_vars" {
  description = "Environment variables to pass to the container"
  type        = map(string)
}

variable "mcp_client_secret_env_vars" {
  description = "Secure environment variables to pass to the container"
  type        = map(string)
}

variable "mcp_server_cpu" {
  default = 512
}

variable "mcp_server_memory" {
  default = 1024
}

variable "mcp_server_container_image" {}

variable "mcp_server_mount_points" {
  type = list(map(string))
}

variable "mcp_server_env_vars" {
  description = "Environment variables to pass to the container"
  type        = map(string)
}

variable "mcp_server_secret_env_vars" {
  description = "Secure environment variables to pass to the container"
  type        = map(string)
}

variable "network_private_subnets" {
  type = list(string)
}

variable "interservice_security_group_id" {}
variable "service_egress_security_group_id" {}
variable "service_lb_security_group_id" {}
