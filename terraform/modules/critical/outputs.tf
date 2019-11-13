output "efs_id" {
  value = aws_efs_file_system.efs.id
}

output "efs_security_group_id" {
  value = aws_security_group.efs.id
}

output "redis_server" {
  value = aws_elasticache_cluster.archivematica.cache_nodes.0.address
}

output "redis_port" {
  value = aws_elasticache_cluster.archivematica.cache_nodes.0.port
}

output "interservice_security_group_id" {
  value = aws_security_group.interservice.id
}

output "rds_host" {
  value = aws_rds_cluster.archivematica.endpoint
}

output "rds_port" {
  value = aws_rds_cluster.archivematica.port
}

output "ingests_bucket_arn" {
  value = aws_s3_bucket.archivematica_ingests.arn
}

output "transfer_source_bucket_arn" {
  value = aws_s3_bucket.archivematica_transfer_source.arn
}

output "transfer_source_bucket_name" {
  value = aws_s3_bucket.archivematica_transfer_source.id
}
