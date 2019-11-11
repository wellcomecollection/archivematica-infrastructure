variable "public_subnets" {
  type = "list"
}

variable "vpc_id" {}
variable "certificate_arn" {}
variable "name" {}

variable "service_lb_security_group_ids" {
  type = "list"
}

variable "idle_timeout" {}
