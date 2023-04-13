variable "namespace" {}

variable "network_private_subnets" {}
variable "vpc_id" {}

variable "rds_username" {}
variable "rds_password" {}

variable "unpacker_task_role_arn" {}

variable "ebs_volume_size" {
  description = "How much EBS storage you need. A good rule of thumb is to have ~3x the size of the largest package you expect to process."
  type = number
}
