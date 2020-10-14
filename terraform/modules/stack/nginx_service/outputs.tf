output "service_name" {
  value = local.full_name
}

output "hostname" {
  value = var.hostname
}

output "task_role_name" {
  value = module.service.task_role_name
}