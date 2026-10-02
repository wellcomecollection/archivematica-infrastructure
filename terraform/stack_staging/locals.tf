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
    # Published before the rebase; runtime overlay files match
    # archivematica-apps/archivematica-storage-service/overlay in this revision.
    am_storage_service = "b39daf5d9c4afb290719df0ca6f61a6109e34377-e25ed79d11cb71d9569506d6d493cf25b2c3d54a"
    clamavd            = "5e40a69bcf4381fe11428324d487fdbb9c828b43"
    nginx              = "120f7da2bd3a1377974ae1f5523711694d1ba11c"
  }

  ecr_image_digests = {
    # Built from 7339cb95717d19ba1bd0bba2f1b772b38a6dd16b before the rebase.
    # Runtime files match archivematica-apps/archivematica-observability
    # in this revision; subsequent changes affect only tests and documentation.
    observability = "sha256:232f3fb7ebf7cd67881cad4d0651bae4e1a973ebc9bc1b4f4779564e1f4efbaf"
  }
}
