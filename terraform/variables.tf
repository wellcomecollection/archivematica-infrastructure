variable "region" {
  default = "eu-west-1"
}

variable "release_ids" {
 type = "map"
}
#
# variable "name" {
#   default = "archivematica"
# }
#
# variable "key_name" {}
#
# variable "controlled_access_cidr_ingress" {
#   default = "195.143.129.128/25"
# }
#
# variable "asg_min" {
#   default = "1"
# }
#
# variable "asg_desired" {
#   default = "1"
# }
#
# variable "asg_max" {
#   default = "2"
# }
#
# variable "instance_type" {
#   default = "t2.large"
# }
#
# variable "listener_port" {
#   default = "443"
# }
#
# variable "aws_region" {
#   default = "eu-west-1"
# }
#
# variable "certificate_domain" {
#   default = "archivematica.wellcomecollection.org"
# }
#
# variable "nginx_container_image" {
#   default = "760097843905.dkr.ecr.eu-west-1.amazonaws.com/uk.ac.wellcome/nginx_api-gw:bad0dbfa548874938d16496e313b05adb71268b7"
# }
#
# variable "dashboard_container_image_base" {
#   default = "760097843905.dkr.ecr.eu-west-1.amazonaws.com/archivematica_dashboard"
# }
#
# variable "storage_container_image_base" {
#   default = "760097843905.dkr.ecr.eu-west-1.amazonaws.com/archivematica_storage_service"
# }
#

