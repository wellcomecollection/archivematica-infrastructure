locals {
  ingests_drop_bucket_name = "wellcomecollection-storage-ingests"
}

resource "aws_s3_bucket_policy" "ingests_put" {
  bucket = "${local.ingests_drop_bucket_name}"
  policy = "${data.aws_iam_policy_document.ingests_put.json}"

  provider = "aws.storage"
}

data "aws_iam_policy_document" "ingests_put" {
  statement {
    actions = [
      "s3:Put*",
      "s3:Get*",
    ]

     resources = [
       "arn:aws:s3:::${local.ingests_drop_bucket_name}",
       "arn:aws:s3:::${local.ingests_drop_bucket_name}/*",
    ]

     principals {
      type = "AWS"

       identifiers = [
        "${aws_iam_role_policy.storage_service_task_role_policy.arn}",
      ]
    }
  }
}
