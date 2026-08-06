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
    dashboard          = "306db6773216e607cf5687f84fb0be353949ddb7-9e548c1d89ffe0707eddc75047c3bcd7d9901710"
    mcp_client         = "306db6773216e607cf5687f84fb0be353949ddb7-9e548c1d89ffe0707eddc75047c3bcd7d9901710"
    mcp_server         = "306db6773216e607cf5687f84fb0be353949ddb7-9e548c1d89ffe0707eddc75047c3bcd7d9901710"
    am_storage_service = "e1996eb9c7ce7488a4ce31175bb25efe125e58bd-9e548c1d89ffe0707eddc75047c3bcd7d9901710"
    clamavd            = "5e40a69bcf4381fe11428324d487fdbb9c828b43"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }
}
