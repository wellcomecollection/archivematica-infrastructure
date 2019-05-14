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
