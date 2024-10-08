locals {
  prod_elasticache_id    = "archivematica"
  staging_elasticache_id = "archivematica-${var.namespace}"

  elasticache_id = var.namespace == "prod" ? local.prod_elasticache_id : local.staging_elasticache_id
}

resource "aws_elasticache_subnet_group" "archivematica" {
  name       = "${local.elasticache_id}-elasticache"
  subnet_ids = var.network_private_subnets
}

resource "aws_elasticache_cluster" "archivematica" {
  cluster_id           = local.elasticache_id
  engine               = "redis"
  node_type            = "cache.t3.medium"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.x"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.archivematica.name
  security_group_ids = [aws_security_group.interservice.id]

  # For some reason Terraform wants this to alternately be 7.x/7.0,
  # so just tell it to ignore it.  When we come to upgrade it, we can
  # remove this `ignore_changes`.
  lifecycle {
    ignore_changes = [engine_version]
  }
}
