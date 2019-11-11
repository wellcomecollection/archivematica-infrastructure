resource "aws_elasticache_subnet_group" "archivematica" {
  name       = "archivematica-${var.namespace}-elasticache"
  subnet_ids = var.network_private_subnets
}

resource "aws_elasticache_cluster" "archivematica" {
  cluster_id           = "archivematica-${var.namespace}"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.archivematica.name
  security_group_ids = [aws_security_group.interservice.id]
}
