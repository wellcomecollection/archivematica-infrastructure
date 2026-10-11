data "aws_region" "observability" {}
data "aws_caller_identity" "observability" {}
data "aws_partition" "observability" {}

module "observability" {
  source = "../observability"

  depends_on = [aws_ecs_cluster.archivematica]

  collector_image = var.observability_collector_image

  subnets            = var.network_private_subnets
  security_group_ids = [var.interservice_security_group_id, var.service_egress_security_group_id]

  enabled       = var.observability_enabled
  environment   = var.namespace
  region        = data.aws_region.observability.region
  cluster_name  = "archivematica-${var.namespace}"
  cluster_arn   = "arn:${data.aws_partition.observability.partition}:ecs:${data.aws_region.observability.region}:${data.aws_caller_identity.observability.account_id}:cluster/archivematica-${var.namespace}"
  ebs_volume_id = var.ebs_volume_id

  # The monitoring view includes both EC2 tasks and the Fargate antivirus tasks.
  service_names = [for name in [
    "dashboard", "storage-service", "mcp_server", "mcp_client", "gearman", "clamav"
  ] : "am-${var.namespace}-${name}"]
}
