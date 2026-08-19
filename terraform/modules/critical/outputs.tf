output "interservice_security_group_id" {
  value = aws_security_group.interservice.id
}

output "rds_host" {
  value = module.aurora_rds_cluster.rds_host
}

output "rds_port" {
  value = module.aurora_rds_cluster.rds_port
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

output "ebs_volume_id" {
  value = aws_ebs_volume.ebs.id
}
