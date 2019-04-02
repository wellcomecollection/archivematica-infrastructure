variable "efs_host_path" {}

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