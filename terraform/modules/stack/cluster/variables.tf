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
