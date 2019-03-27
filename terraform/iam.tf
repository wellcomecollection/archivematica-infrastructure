locals {
  ingests_drop_bucket_name = "wellcomecollection-storage-ingests"
}

# Give permission for the storage service microservice to upload objects to
# the ingests drop bucket.

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
        "${module.storage_service.task_role_arn}",
      ]
    }
  }
}

resource "aws_iam_role_policy" "storage_service_task_role_policy" {
  role   = "${module.storage_service.task_role_name}"
  policy = "${data.aws_iam_policy_document.storage_service_aws_permissions.json}"
}


data "aws_iam_policy_document" "storage_service_aws_permissions" {
  statement {
    actions = [
      "s3:Put*",
    ]

    # TODO: Scope this more tightly to a location specifically for Archivematica.
    resources = [
      "arn:aws:s3:::${local.ingests_drop_bucket_name}/*",
    ]
  }
}
