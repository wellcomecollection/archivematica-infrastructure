output "redis_server" {
  value = module.critical.redis_server
}

output "redis_port" {
  value = module.critical.redis_port
}

output "interservice_security_group_id" {
  value = module.critical.interservice_security_group_id
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
