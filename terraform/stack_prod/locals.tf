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
    dashboard          = "v1.17.1-3f3444807015e98865d9e137ac9d1ae7e26088f0"
    mcp_client         = "v1.17.1-3f3444807015e98865d9e137ac9d1ae7e26088f0"
    mcp_server         = "v1.17.1-3f3444807015e98865d9e137ac9d1ae7e26088f0"
    am_storage_service = "v0.23.0-3f3444807015e98865d9e137ac9d1ae7e26088f0"
    clamavd            = "f60df7b65fe0e405d89191053f7196a1769e4ccf"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }
}
