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
