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
    dashboard          = "v1.14.1-3abac53f15ab2a9ae60f79f68e0ef0c9eb81191c"
    mcp_client         = "v1.14.1-3abac53f15ab2a9ae60f79f68e0ef0c9eb81191c"
    mcp_server         = "v1.14.1-3abac53f15ab2a9ae60f79f68e0ef0c9eb81191c"
    am_storage_service = "v0.20.1-1b8e2c65aff6913122a7de72bc9027f36cf68129"
    clamavd            = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }
}
