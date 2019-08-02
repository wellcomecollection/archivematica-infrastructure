resource "aws_elasticache_subnet_group" "archivematica" {
  name       = "archivematica-elasticache-subnet-group"
  subnet_ids = ["${local.network_private_subnets}"]
}

resource "aws_elasticache_cluster" "archivematica" {
  cluster_id           = "archivematica"
  engine               = "redis"
  node_type            = "cache.m4.large"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379

  subnet_group_name  = "${aws_elasticache_subnet_group.archivematica.name}"
  security_group_ids = ["${local.interservice_security_group_id}"]
}
