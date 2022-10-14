locals {
  monitoring_outputs = data.terraform_remote_state.monitoring.outputs

  lambda_error_alarm_arn = local.monitoring_outputs["workflow_lambda_error_alerts_topic_arn"]

  infra_state = data.terraform_remote_state.infra.outputs

  ecr_dashboard_repo_url       = local.infra_state["ecr_dashboard_repo_url"]
  ecr_mcp_client_repo_url      = local.infra_state["ecr_mcp_client_repo_url"]
  ecr_mcp_server_repo_url      = local.infra_state["ecr_mcp_server_repo_url"]
  ecr_storage_service_repo_url = local.infra_state["ecr_storage_service_repo_url"]
}
