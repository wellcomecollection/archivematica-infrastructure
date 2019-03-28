resource "aws_iam_role_policy" "storage_service_task_role_policy" {
  role   = "${module.storage_service.task_role_name}"
  policy = "${data.aws_iam_policy_document.storage_service_aws_permissions.json}"
}


data "aws_iam_policy_document" "storage_service_aws_permissions" {
  statement {
    actions = [
      "s3:Put*",
    ]

    resources = [
      "${aws_s3_bucket.archivematica_drop.arn}/*",
    ]
  }
}
