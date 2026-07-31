resource "aws_dynamodb_table" "s3_start_transfer_events" {
  name         = "archivematica-s3-start-transfer-events-${var.namespace}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "event_id"

  attribute {
    name = "event_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

module "s3_start_transfer_lambda" {
  source     = "./lambda"
  handler    = "s3_start_transfer.main"
  source_dir = "${path.module}/../../../lambdas/s3_start_transfer/src"

  description     = "Trigger that starts new Archivematica transfers from an upload to ${var.transfer_source_bucket_name}"
  name            = "archivematica-s3_start_transfer-${var.namespace}"
  alarm_topic_arn = var.lambda_error_alarm_arn

  environment = {
    "ARCHIVEMATICA_URL"         = "https://${module.dashboard_service.hostname}"
    "ARCHIVEMATICA_SS_URL"      = "https://${module.storage_service.hostname}"
    "ARCHIVEMATICA_USERNAME"    = var.archivematica_username
    "ARCHIVEMATICA_API_KEY"     = var.archivematica_api_key
    "ARCHIVEMATICA_SS_USERNAME" = var.archivematica_ss_username
    "ARCHIVEMATICA_SS_API_KEY"  = var.archivematica_ss_api_key
    "IDEMPOTENCY_TABLE_NAME"    = aws_dynamodb_table.s3_start_transfer_events.name
  }

  timeout = 120
}

resource "aws_lambda_permission" "allow_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket_${module.s3_start_transfer_lambda.function_name}"
  action        = "lambda:InvokeFunction"
  function_name = module.s3_start_transfer_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.transfer_source_bucket_arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  provider = aws.digitisation

  bucket = var.transfer_source_bucket_name

  lambda_function {
    lambda_function_arn = module.s3_start_transfer_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".zip"
  }
}

data "aws_iam_policy_document" "allow_writing_log_files" {
  statement {
    actions = [
      "s3:Head*",
      "s3:Get*",
      "s3:Put*",
    ]

    resources = [
      "${var.transfer_source_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "allow_writing_log_files" {
  role   = module.s3_start_transfer_lambda.role_name
  policy = data.aws_iam_policy_document.allow_writing_log_files.json
}

data "aws_iam_policy_document" "allow_s3_start_transfer_idempotency" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]

    resources = [
      aws_dynamodb_table.s3_start_transfer_events.arn,
    ]
  }
}

resource "aws_iam_role_policy" "allow_s3_start_transfer_idempotency" {
  role   = module.s3_start_transfer_lambda.role_name
  policy = data.aws_iam_policy_document.allow_s3_start_transfer_idempotency.json
}
