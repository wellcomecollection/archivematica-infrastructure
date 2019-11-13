locals {
  prod_ingests_bucket_name    = "wellcomecollection-archivematica-ingests"
  staging_ingests_bucket_name = "wellcomecollection-archivematica-${var.namespace}-ingests"

  ingests_bucket_name = "${var.namespace == "prod" ? local.prod_ingests_bucket_name : local.staging_ingests_bucket_name}"
}

resource "aws_s3_bucket" "archivematica_ingests" {
  bucket = local.ingests_bucket_name

  lifecycle_rule {
    expiration {
      days = "30"
    }

    enabled = true
  }
}

resource "aws_s3_bucket_policy" "allow_storage_service_unpacker_ingests_read" {
  bucket = aws_s3_bucket.archivematica_ingests.id
  policy = data.aws_iam_policy_document.allow_ingests_bucket_read.json
}

data "aws_iam_policy_document" "allow_ingests_bucket_read" {
  statement {
    actions = [
      "s3:Get*",
    ]

    resources = [
      "${aws_s3_bucket.archivematica_ingests.arn}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        var.unpacker_task_role_arn,
      ]
    }
  }
}
