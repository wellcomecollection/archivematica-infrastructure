output "ingests_bucket" {
  value = "${aws_s3_bucket.archivematica_drop.id}"
}
