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
