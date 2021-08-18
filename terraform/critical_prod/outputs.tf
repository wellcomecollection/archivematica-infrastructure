output "redis_server" {
  value = module.critical.redis_server
}

output "redis_port" {
  value = module.critical.redis_port
}

output "interservice_security_group_id" {
  value = module.critical.interservice_security_group_id
}

# TODO: Don't put these in the unencrypted state file!
output "rds_username" {
  value     = local.rds_username
  sensitive = true
}

output "rds_password" {
  value     = local.rds_password
  sensitive = true
}

output "rds_host" {
  value = module.critical.rds_host
}

output "rds_port" {
  value = module.critical.rds_port
}

output "ingests_bucket_arn" {
  value = module.critical.ingests_bucket_arn
}

output "transfer_source_bucket_arn" {
  value = module.critical.transfer_source_bucket_arn
}

output "transfer_source_bucket_name" {
  value = module.critical.transfer_source_bucket_name
}

output "ebs_volume_id" {
  value = module.critical.ebs_volume_id
}
