output "service_name" {
  value = "${module.service.name}"
}

output "task_role_arn" {
  value = "${module.task_definition.task_role_arn}"
}

output "task_role_name" {
  value = "${module.task_definition.task_role_name}"
}

output "hostname" {
  value = "${var.hostname}"
}
