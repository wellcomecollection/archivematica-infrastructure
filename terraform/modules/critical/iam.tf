resource "aws_s3_bucket_policy" "allow_storage_service_unpacker_drop_read" {
  bucket = aws_s3_bucket.archivematica_drop.id
  policy = data.aws_iam_policy_document.allow_drop_bucket_read.json
}

data "aws_iam_policy_document" "allow_drop_bucket_read" {
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
        var.unpacker_task_role_arn,
      ]
    }
  }
}
