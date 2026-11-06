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

variable "turn_off_outside_office_hours" {
  type    = bool
  default = false
}

# Sidecar image tags are set centrally in platform-infrastructure/sidecars/terraform.
variable "sidecar_tier" {
  type = string

  validation {
    condition     = contains(["stage", "prod"], var.sidecar_tier)
    error_message = "sidecar_tier must be stage or prod."
  }
}

# Pins this service to a tag instead of the tier's parameter.
variable "fluentbit_tag_override" {
  type    = string
  default = null
}
