variable "vpc_id" {}
variable "instance_type" {}
variable "ebs_volume_id" {}

variable "private_subnets" {
  type = list(string)
}

variable "cluster_name" {}

variable "container_host_ami" {
  description = "The AMI to use for the container host"
  type        = string
}
