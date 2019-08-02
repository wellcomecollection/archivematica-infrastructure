resource "aws_s3_bucket" "archivematica_drop" {
  bucket = "wellcomecollection-archivematica-ingests"
  acl    = "private"

  lifecycle_rule {
    expiration {
      days = "30"
    }

    enabled = true
  }
}

resource "aws_s3_bucket" "archivematica_transfer" {
  bucket = "wellcomecollection-archivematica-transfer-source"
  acl    = "private"
}

resource "aws_s3_bucket_policy" "archivematica_transfer" {
  bucket = "${aws_s3_bucket.archivematica_transfer.id}"
  policy = "${data.aws_iam_policy_document.archivematica_transfer.json}"
}

data "aws_iam_policy_document" "archivematica_transfer" {
  "statement" {
    actions = [
      "s3:List*",
      "s3:Get*",
      "s3:Delete*",
      "s3:Put*",
    ]

    resources = [
      "${aws_s3_bucket.archivematica_transfer.arn}/*"
    ]

    principals {
      identifiers = [
        "arn:aws:iam::404315009621:role/digitisation-developer"
      ]
      type = "AWS"
    }
  }
}

