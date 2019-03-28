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
