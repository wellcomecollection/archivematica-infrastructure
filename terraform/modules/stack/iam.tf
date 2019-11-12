resource "aws_iam_role_policy" "storage_service_task_role_policy" {
  role   = module.storage_service.task_role_name
  policy = data.aws_iam_policy_document.storage_service_aws_permissions.json
}

data "aws_iam_policy_document" "storage_service_aws_permissions" {
  statement {
    actions = [
      "s3:Put*",
    ]

    resources = [
      "${var.ingests_bucket_arn}",
      "${var.ingests_bucket_arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      var.transfer_source_bucket_arn,
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
      "${var.transfer_source_bucket_arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      "${var.storage_service_bucket_arn}/*",
      "${var.storage_service_bucket_arn}",
    ]
  }
}
