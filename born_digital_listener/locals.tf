locals {
  lambda_error_alarm_arn = local.monitoring_outputs["workflow_lambda_error_alerts_topic_arn"]
  dlq_alarm_arn          = local.monitoring_outputs["storage_dlq_alarm_topic_arn"]
}