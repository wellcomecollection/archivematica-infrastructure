variable "region" {
  default = "eu-west-1"
}

variable "rds_admin_cidr_ingress" {}

variable "rds_username" {}
variable "rds_password" {}

variable "admin_cidr_ingress" {
  type = "list"
}
