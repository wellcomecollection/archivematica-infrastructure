module "s3_start_transfer_lambda" {
  source      = "./lambda"
  s3_bucket   = "wellcomecollection-workflow-infra"
  s3_key      = "lambdas/s3_start_transfer.zip"
  module_name = "s3_start_transfer"

  description     = "Start new Archivematica transfers for uploads to transfer bucket"
  name            = "archivematica-s3_start_transfer-${var.namespace}"
  alarm_topic_arn = var.lambda_error_alarm_arn

  environment_variables = {
    "ARCHIVEMATICA_URL"         = "https://${module.dashboard_service.hostname}"
    "ARCHIVEMATICA_SS_URL"      = "https://${module.storage_service.hostname}"
    "ARCHIVEMATICA_USERNAME"    = var.archivematica_username
    "ARCHIVEMATICA_API_KEY"     = var.archivematica_api_key
    "ARCHIVEMATICA_SS_USERNAME" = var.archivematica_ss_username
    "ARCHIVEMATICA_SS_API_KEY"  = var.archivematica_ss_api_key
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
