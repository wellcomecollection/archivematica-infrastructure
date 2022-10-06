variable "environment" {
  type = string
}

variable "input_topic" {
  description = "The SNS topic of newly registered bags in the storage service"
  type        = string
}

variable "lambda_error_alarm_arn" {
  type = string
}

variable "dlq_alarm_arn" {
  type = string
}