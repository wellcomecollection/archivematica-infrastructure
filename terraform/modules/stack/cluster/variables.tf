variable "vpc_id" {}
variable "name" {}
variable "region" {}
variable "instance_type" {}
variable "ebs_volume_id" {}
variable "key_name" {}

variable "controlled_access_cidr_ingress" {
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "cluster_name" {}

variable "container_host_ami" {
  description = "The AMI to use for the container host"
  type = string
}

variable "bastion_host_ami" {
  description = "The AMI to use for the bastion host"
  type = string
}