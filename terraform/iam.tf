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

resource "aws_s3_bucket_policy" "archivematica_ingests_bucket_policy" {
  bucket = "${aws_s3_bucket.archivematica_drop.id}"
  policy = "${data.aws_iam_policy_document.archivematica_ingests_bucket_policy.json}"
}

data "aws_iam_policy_document" "archivematica_ingests_bucket_policy" {
  statement {
    actions = [
      "s3:Get*",
    ]

    resources = [
      "${aws_s3_bucket.archivematica_drop.arn}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${data.terraform_remote_state.storage_service.unpacker_task_role_arns}"
      ]
    }
  }
}