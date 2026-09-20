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
    dashboard          = "887d3a24b89de0f1bddbe6c85004e6d1d50487b4-a580464fd2728481dd24d619e200cfdd13f83bdb"
    mcp_client         = "887d3a24b89de0f1bddbe6c85004e6d1d50487b4-a580464fd2728481dd24d619e200cfdd13f83bdb"
    mcp_server         = "887d3a24b89de0f1bddbe6c85004e6d1d50487b4-a580464fd2728481dd24d619e200cfdd13f83bdb"
    am_storage_service = "d08d6e73ba352f3ae6c3d48ee50369ddfa3419c2-a580464fd2728481dd24d619e200cfdd13f83bdb"
    clamavd            = "5e40a69bcf4381fe11428324d487fdbb9c828b43"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }
}
