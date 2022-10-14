locals {
  prod_bucket_name    = "wellcomecollection-archivematica-transfer-source"
  staging_bucket_name = "wellcomecollection-archivematica-${var.namespace}-transfer-source"

  bucket_name = var.namespace == "prod" ? local.prod_bucket_name : local.staging_bucket_name
}

resource "aws_s3_bucket" "archivematica_transfer_source" {
  provider = aws.digitisation

  bucket = local.bucket_name
}

resource "aws_s3_bucket_policy" "archivematica_transfer_source" {
  provider = aws.digitisation

  bucket = aws_s3_bucket.archivematica_transfer_source.id
  policy = data.aws_iam_policy_document.archivematica_transfer_source.json
}

data "aws_iam_policy_document" "archivematica_transfer_source" {
  statement {
    actions = [
      "s3:Delete*",
      "s3:Get*",
      "s3:List*",
      "s3:Put*",
    ]

    resources = [
      aws_s3_bucket.archivematica_transfer_source.arn,
      "${aws_s3_bucket.archivematica_transfer_source.arn}/*",
    ]

    principals {
      identifiers = [
        "arn:aws:iam::975596993436:role/storage-developer",
        "arn:aws:iam::404315009621:role/digitisation-developer",
        "arn:aws:iam::299497370133:root", # workflow account
      ]

      type = "AWS"
    }
  }
}
