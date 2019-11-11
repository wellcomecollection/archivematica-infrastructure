output "efs_id" {
  value = module.critical.efs_id
}

output "efs_security_group_id" {
  value = module.critical.efs_security_group_id
}

output "redis_server" {
  value = module.critical.redis_server
}

output "redis_port" {
  value = module.critical.redis_port
}

output "interservice_security_group_id" {
  value = module.critical.interservice_security_group_id
}
