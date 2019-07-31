output "ingests_bucket" {
  value = "${aws_s3_bucket.archivematica_drop.id}"
}

output "storage_service_task_role_arn" {
  value = "${module.storage_service.task_role_name}"
}
