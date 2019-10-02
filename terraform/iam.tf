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
      "${aws_s3_bucket.archivematica_drop.arn}",
      "${aws_s3_bucket.archivematica_drop.arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "${aws_s3_bucket.archivematica_transfer.arn}",
    ]
  }

  statement {
    actions = [
      "s3:HeadBucket",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.archivematica_transfer.arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      "arn:aws:s3:::wellcomecollection-storage/*",
      "arn:aws:s3:::wellcomecollection-storage",
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
        "${data.terraform_remote_state.storage_service_prod.unpacker_task_role_arn}",
        "${data.terraform_remote_state.storage_service_staging.unpacker_task_role_arn}",
      ]
    }
  }
}
