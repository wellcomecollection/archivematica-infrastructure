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
    dashboard  = "cbc6cfde909f19b45992250429d1b89a799fdc7c-145e1f91faebc8506031d470246bff6c51888214"
    mcp_client = "cbc6cfde909f19b45992250429d1b89a799fdc7c-145e1f91faebc8506031d470246bff6c51888214"
    mcp_server = "cbc6cfde909f19b45992250429d1b89a799fdc7c-145e1f91faebc8506031d470246bff6c51888214"
    # Built with overlay commit 66558f1af840eae64e608d08315c412ab5f07a72.
    am_storage_service = "b39daf5d9c4afb290719df0ca6f61a6109e34377-66558f1af840eae64e608d08315c412ab5f07a72"
    clamavd            = "5e40a69bcf4381fe11428324d487fdbb9c828b43"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }

  ecr_image_digests = {
    # Published from commit 66558f1af840eae64e608d08315c412ab5f07a72.
    observability = "sha256:8fdb10d617a71aea71dea7683235849f59af32078421f20788095b7fc1325e7c"
  }
}
