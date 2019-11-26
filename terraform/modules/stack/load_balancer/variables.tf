variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {}
variable "certificate_arn" {}
variable "name" {}

variable "service_lb_security_group_ids" {
  type = list(string)
}

variable "idle_timeout" {}
