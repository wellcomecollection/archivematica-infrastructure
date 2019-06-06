output "service_name" {
  value = "${module.service.service_name}"
}

output "task_role_arn" {
  value = "${module.iam_roles.task_role_arn}"
}

output "task_role_name" {
  value = "${module.iam_roles.name}"
}

output "hostname" {
  value = "${var.hostname}"
}
