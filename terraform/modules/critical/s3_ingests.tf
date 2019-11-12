resource "aws_s3_bucket" "archivematica_ingests" {
  bucket = "wellcomecollection-archivematica-${var.namespace}-ingests"
  acl    = "private"
}

