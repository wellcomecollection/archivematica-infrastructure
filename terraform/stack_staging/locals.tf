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
    observability      = local.infra_state["ecr_observability_repo_url"]
  }

  ecr_image_tags = {
    dashboard  = "beaa1c69fad60f7825c15648914e619052360a48-5449fed838674d45290ac4995ec3f8d5e2b000ea"
    mcp_client = "beaa1c69fad60f7825c15648914e619052360a48-5449fed838674d45290ac4995ec3f8d5e2b000ea"
    mcp_server = "beaa1c69fad60f7825c15648914e619052360a48-5449fed838674d45290ac4995ec3f8d5e2b000ea"
    # Built with overlay commit 5449fed838674d45290ac4995ec3f8d5e2b000ea.
    am_storage_service = "aa0797d93d1fc4e48803d6d2546cb85c5ebebceb-5449fed838674d45290ac4995ec3f8d5e2b000ea"
    clamavd            = "5e40a69bcf4381fe11428324d487fdbb9c828b43"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }

  ecr_image_digests = {
    # Published from commit 66558f1af840eae64e608d08315c412ab5f07a72.
    observability = "sha256:8fdb10d617a71aea71dea7683235849f59af32078421f20788095b7fc1325e7c"
  }
}
