output "rds_cluster_id" {
  value = aws_rds_cluster.cluster.id
}

output "rds_host" {
  value = aws_rds_cluster.cluster.endpoint
}

output "rds_port" {
  value = aws_rds_cluster.cluster.port
}
