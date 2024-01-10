variable "name" {
  type = string
}

variable "source_dir" {
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

variable "environment" {
  type = map(string)
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 128
}
