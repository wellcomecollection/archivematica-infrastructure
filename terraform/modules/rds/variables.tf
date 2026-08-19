variable "cluster_identifier" {
  type    = string
  default = null
}

variable "database_name" {
  type = string
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}

variable "db_security_group_id" {
  type = string
}

variable "aws_db_subnet_group_name" {
  type = string
}

variable "snapshot_identifier" {
  description = "The snapshot used to create an existing cluster, retained to keep its Terraform state stable"
  type        = string
  default     = null
}

variable "serverlessv2_scaling_configuration" {
  type = object({
    max_capacity = number
    min_capacity = number
  })
  default = null
}

variable "instance_class" {
  type    = string
  default = "db.t4g.medium"
}
