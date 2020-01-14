variable "cluster_name" {}

variable "ebs_volume_id" {}

variable "instance_type" {}

variable "subnets" {
  type = list(string)
}

variable "vpc_id" {}
variable "key_name" {}

variable "controlled_access_cidr_ingress" {
  type        = list(string)
  default     = []
  description = "CIDR for SSH access to EC2 instances"
}

variable "ssh_ingress_security_groups" {
  type    = list(string)
  default = []
}

variable "region" {}
