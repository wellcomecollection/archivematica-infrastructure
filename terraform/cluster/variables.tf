variable "vpc_id" {}
variable "name" {}
variable "region" {}
variable "asg_min" {}
variable "asg_desired" {}
variable "asg_max" {}
variable "instance_type" {}
variable "ebs_size" {}
variable "key_name" {}

variable "controlled_access_cidr_ingress" {
  type = "list"
}

variable "public_subnets" {
  type = "list"
}

variable "private_subnets" {
  type = "list"
}

variable "efs_security_group_ids" {
  type = "list"
}

variable "efs_id" {}
variable "cluster_name" {}
