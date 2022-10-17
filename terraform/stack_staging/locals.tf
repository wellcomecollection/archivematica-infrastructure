locals {
  monitoring_outputs = data.terraform_remote_state.monitoring.outputs

  lambda_error_alarm_arn = local.monitoring_outputs["workflow_lambda_error_alerts_topic_arn"]

  infra_state = data.terraform_remote_state.infra.outputs

  ecr_repo_urls = {
    dashboard          = local.infra_state["ecr_dashboard_repo_url"]
    mcp_client         = local.infra_state["ecr_mcp_client_repo_url"]
    mcp_server         = local.infra_state["ecr_mcp_server_repo_url"]
    am_storage_service = local.infra_state["ecr_storage_service_repo_url"]
    clamavd            = local.infra_state["ecr_clamavd_repo_url"]
    nginx              = local.infra_state["ecr_nginx_repo_url"]
  }

  ecr_image_tags = {
    dashboard          = "v1.13.2-b729efdfe8a84ab98fdb6e1dec83d08a5eba6086"
    mcp_client         = "v1.13.2-b729efdfe8a84ab98fdb6e1dec83d08a5eba6086"
    mcp_server         = "v1.13.2-b729efdfe8a84ab98fdb6e1dec83d08a5eba6086"
    am_storage_service = "v0.19.0-06f74ea"
    clamavd            = "a49d4f9"
    nginx              = "8ed3654"
  }
}
