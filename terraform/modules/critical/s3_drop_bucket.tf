resource "aws_s3_bucket" "archivematica_drop" {
  bucket = "wellcomecollection-archivematica-${var.namespace}-drop-bucket"
  acl    = "private"

  lifecycle_rule {
    expiration {
      days = "30"
    }

    enabled = true
  }
}
