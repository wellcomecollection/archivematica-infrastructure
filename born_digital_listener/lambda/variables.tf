variable "name" {
  type = string
}

variable "filename" {
  type = string
}

variable "handler" {
  type = string
}

variable "description" {
  type = string
}

variable "alarm_topic_arn" {
  description = "ARN of the topic where to send notification for lambda errors"
  type        = string
}

variable "alarm_component" {
  description = "Backplane Component name (metadata.name in manifest.yml) for the error alarm"
  type        = string
}

variable "alarm_severity" {
  description = "Severity of the error alarm: high, medium or low"
  type        = string

  validation {
    condition     = contains(["high", "medium", "low"], var.alarm_severity)
    error_message = "alarm_severity must be high, medium or low."
  }
}

variable "environment" {
  type = map(string)
}

variable "timeout" {
  type    = number
  default = 3
}
