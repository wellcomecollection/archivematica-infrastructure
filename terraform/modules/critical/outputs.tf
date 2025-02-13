output "redis_server" {
  value = aws_elasticache_cluster.archivematica.cache_nodes.0.address
}

output "redis_port" {
  value = aws_elasticache_cluster.archivematica.cache_nodes.0.port
}

output "interservice_security_group_id" {
  value = aws_security_group.interservice.id
}

// NOTE: In order to switch databases, replace with "value = aws_rds_cluster.archivematica.endpoint"
output "rds_host" {
  value = aws_rds_cluster.archivematica.endpoint
}
// NOTE: In order to switch databases, replace with "value = aws_rds_cluster.archivematica.endpoint"
output "rds_port" {
  value = aws_rds_cluster.archivematica.port
}

// NOTE: During migration, apply the critical stack first, then the associated stage/prod stack.
// The prod/stage stack read from the critical stack state outputs when applied!

output "ingests_bucket_arn" {
  value = aws_s3_bucket.archivematica_ingests.arn
}

output "transfer_source_bucket_arn" {
  value = aws_s3_bucket.archivematica_transfer_source.arn
}

output "transfer_source_bucket_name" {
  value = aws_s3_bucket.archivematica_transfer_source.id
}

output "ebs_volume_id" {
  value = aws_ebs_volume.ebs.id
}
