variable "region" {
  default = "eu-west-1"
}

variable "profile" {
  default = "wellcomedigitalplatform"
}

variable "name" {
  default = "archivematica"
}

variable "key_name" {
  default = "wellcomedigitalplatform"
}

variable "controlled_access_cidr_ingress" {
  default = "195.143.129.128/25"
}

variable "asg_min" {
  default = "1"
}

variable "asg_desired" {
  default = "1"
}

variable "asg_max" {
  default = "1"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "listener_port" {
  default = "443"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "certificate_domain" {}
