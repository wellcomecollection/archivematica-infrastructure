resource "aws_s3_bucket" "alb_access_logs" {
  bucket = "wellcomecollection-archivematica-${var.namespace}-alb-logs"
}

resource "aws_s3_bucket_public_access_block" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ALB access logs only support SSE-S3.
resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id

  rule {
    id     = "expire_after_90_days"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }
  }
}

# eu-west-1 delivers ALB logs from the regional Elastic Load Balancing account.
data "aws_iam_policy_document" "alb_access_logs" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.alb_access_logs.arn}/*/AWSLogs/${data.aws_caller_identity.observability.account_id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::156460612806:root"]
    }
  }
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.alb_access_logs.id
  policy = data.aws_iam_policy_document.alb_access_logs.json

  depends_on = [aws_s3_bucket_public_access_block.alb_access_logs]
}
