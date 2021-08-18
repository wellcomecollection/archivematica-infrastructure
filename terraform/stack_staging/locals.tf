locals {
  monitoring_outputs = data.terraform_remote_state.monitoring.outputs

  lambda_error_alarm_arn = local.monitoring_outputs["workflow_lambda_error_alerts_topic_arn"]

  ecr_storage_service_repo_url = data.terraform_remote_state.infra.outputs.ecr_storage_service_repo_url
}
