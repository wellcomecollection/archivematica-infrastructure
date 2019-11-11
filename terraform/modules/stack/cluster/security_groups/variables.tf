variable "custom_security_groups" {
  type    = "list"
  default = []
}

variable "vpc_id" {}
variable "name" {}

variable "controlled_access_cidr_ingress" {
}

variable "controlled_access_security_groups" {
  type    = "list"
  default = []
}
