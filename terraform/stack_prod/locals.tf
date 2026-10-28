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
    dashboard          = "aa2fc87f50ffffde4cc26728cf45c9c58bdb5238-193d709de5f62bcfadc4c8eef17ab8b278e12f73"
    mcp_client         = "aa2fc87f50ffffde4cc26728cf45c9c58bdb5238-193d709de5f62bcfadc4c8eef17ab8b278e12f73"
    mcp_server         = "aa2fc87f50ffffde4cc26728cf45c9c58bdb5238-193d709de5f62bcfadc4c8eef17ab8b278e12f73"
    am_storage_service = "0332eed8c25707ccf48b2b3dfc5fae68db39ba27-193d709de5f62bcfadc4c8eef17ab8b278e12f73"
    clamavd            = "bad6aebe18f7462f0bcf8d2c5804fd0643a27dbc"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }

  ecr_image_digests = {
    # Published from commit 7d0a10c6ad847b8d4fafdb623f18a89caa12a2cb.
    observability = "sha256:afa756ba0f628a49f81581033e57a802f736da2d87ba1071a1b72c3a2d9aca20"
  }
}
