variable "cluster_name" {}

variable "ebs_volume_id" {}

variable "instance_type" {}

variable "subnets" {
  type = list(string)
}

variable "vpc_id" {}
variable "key_name" {}

variable "container_host_ami" {
  description = "The AMI to use for the container host"
  type        = string
}
