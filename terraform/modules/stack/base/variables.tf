variable "service_name" {
  type = string
}

variable "container_definitions" {}

variable "cpu" {
  type = number
}

variable "memory" {
  type = number
}

variable "cluster_arn" {
  type = string
}

variable "service_discovery_namespace_id" {
  type    = string
  default = ""
}

variable "subnets" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "desired_task_count" {
  type = number
}

variable "use_fargate_spot" {
  type    = bool
  default = false
}

variable "target_group_arn" {
  type    = string
  default = ""
}

variable "container_name" {
  type    = string
  default = ""
}

variable "container_port" {
  type    = string
  default = ""
}

variable "launch_type" {
  type = string
}

variable "placement_constraints" {
  type = list(object({
    type       = string
    expression = string
  }))
  default = []
}

variable "volumes" {
  type = list(object({
    name      = string
    host_path = string
  }))
  default = []
}

variable "deployment_minimum_healthy_percent" {
  type = number
}

variable "deployment_maximum_percent" {
  type = number
}