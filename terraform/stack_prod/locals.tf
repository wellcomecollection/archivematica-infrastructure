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
    dashboard          = "569f09215ce2eb3de353656cfa47a6a86639c1b6-f12421cecdfaf859589bf096cbe854aac5c95ac7"
    mcp_client         = "569f09215ce2eb3de353656cfa47a6a86639c1b6-f12421cecdfaf859589bf096cbe854aac5c95ac7"
    mcp_server         = "569f09215ce2eb3de353656cfa47a6a86639c1b6-f12421cecdfaf859589bf096cbe854aac5c95ac7"
    am_storage_service = "324f1cfcabe1a3ad9e4a9191735e8e9367f52456-089574dc166d70a568d208a886898781a8b0dd50"
    clamavd            = "5e40a69bcf4381fe11428324d487fdbb9c828b43"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }
}
