variable "enabled" {
  type        = bool
  description = "Collect application, host and ECS metrics and lifecycle events. The caller also configures the ECS cluster's Container Insights setting."
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "ebs_volume_id" {
  type = string
}

variable "service_names" {
  type = set(string)
}
