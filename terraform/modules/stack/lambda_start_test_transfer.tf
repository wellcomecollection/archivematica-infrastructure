module "start_test_transfer_lambda" {
  source     = "./lambda"
  handler    = "start_test_transfer.main"
  source_dir = "${path.module}/../../../start_test_transfer/src"

  description     = "Send a test transfer package to Archivematica"
  name            = "archivematica-start_test_transfer-${var.namespace}"
  alarm_topic_arn = var.lambda_error_alarm_arn

  environment = {
    "UPLOAD_BUCKET" = var.transfer_source_bucket_name
  }

  timeout = 30
}

data "aws_iam_policy_document" "allow_writing_to_uploads_bucket" {
  statement {
    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${var.transfer_source_bucket_arn}/born-digital/*",
    ]
  }
}

resource "aws_iam_role_policy" "allow_writing_to_uploads_bucket" {
  role   = module.start_test_transfer_lambda.role_name
  policy = data.aws_iam_policy_document.allow_writing_to_uploads_bucket.json
}
