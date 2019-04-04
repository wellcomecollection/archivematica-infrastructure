variable "cluster_id" {}
variable "namespace_id" {}

variable "fits_cpu" {
  default = 1024
}

variable "fits_memory" {
  default = 1536
}

variable "fits_container_image" {}

variable "fits_mount_points" {
  type = "list"
}

variable "clamav_cpu" {
  default = 1024
}

variable "clamav_memory" {
  default = 1536
}

variable "clamav_container_image" {}

variable "clamav_mount_points" {
  type = "list"
}


variable "mcp_client_cpu" {
  default = 1024
}

variable "mcp_client_memory" {
  default = 1536
}

variable "mcp_client_container_image" {}

variable "mcp_client_mount_points" {
  type = "list"
}

variable "mcp_client_env_vars" {
  description = "Environment variables to pass to the container"
  type        = "map"
}

variable "mcp_client_env_vars_length" {}

variable "mcp_client_secret_env_vars" {
  description = "Secure environment variables to pass to the container"
  type        = "map"
}

variable "mcp_client_secret_env_vars_length" {}
