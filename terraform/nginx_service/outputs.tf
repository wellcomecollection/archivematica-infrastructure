output "service_name" {
  value = "${module.service.service_name}"
}

output "task_role_name" {
  value = "${module.iam_roles.name}"
}
