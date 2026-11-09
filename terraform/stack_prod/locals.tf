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
    clamavd            = "f997f9c0b75c01a33e0b733c8f3eaf2c57605543"
    nginx              = "0edcf0a26153c380b6026e4784bccbd052774573"
  }

  ecr_image_digests = {
    # Published from commit a1c5b53d205cc91c68abb4aa29d4531936395d77.
    observability = "sha256:a8c9b375b327a7f62a6a00c2a893382846f803a5712f9acc33b17b3c102e4437"
  }
}
