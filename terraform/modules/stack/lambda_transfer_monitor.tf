module "transfer_monitor_lambda" {
  source     = "./lambda"
  handler    = "transfer_monitor.main"
  source_dir = "${path.module}/../../../lambdas/transfer_monitor/src"

  description     = "Report on the state of Archivematica transfers (${var.namespace})"
  name            = "archivematica-transfer_monitor-${var.namespace}"
  alarm_topic_arn = var.lambda_error_alarm_arn

  environment = {
    TRANSFER_BUCKET       = var.transfer_source_bucket_name
    REPORTING_FILES_INDEX = var.namespace == "prod" ? "storage_files" : "storage_stage_files"
    DAYS_TO_CHECK         = 14
    ENVIRONMENT           = var.namespace
  }

  timeout = 300
}

data "aws_iam_policy_document" "allow_reading_and_deleting_from_uploads_bucket" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
      "s3:DeleteObject",
    ]

    resources = [
      var.transfer_source_bucket_arn,
      "${var.transfer_source_bucket_arn}*",
    ]
  }
}

resource "aws_iam_role_policy" "allow_reading_and_deleting_from_uploads_bucket" {
  role   = module.transfer_monitor_lambda.role_name
  policy = data.aws_iam_policy_document.allow_reading_and_deleting_from_uploads_bucket.json
}

data "aws_iam_policy_document" "allow_reading_transfer_monitor_secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]

    resources = [
      "arn:aws:secretsmanager:eu-west-1:299497370133:secret:archivematica/transfer_monitor/*"
    ]
  }
}

resource "aws_iam_role_policy" "allow_reading_transfer_monitor_secrets" {
  role   = module.transfer_monitor_lambda.role_name
  policy = data.aws_iam_policy_document.allow_reading_transfer_monitor_secrets.json
}

# Schedule the reporter to run at 6:15 every Monday.  This is slightly
# after the daily report from the storage service, so they'll always appear
# in a consistent order.

resource "aws_cloudwatch_event_rule" "every_monday_at_6_15" {
  name                = "trigger_transfer_monitor"
  schedule_expression = "cron(15 6 ? * MON *)"
}

resource "aws_lambda_permission" "allow_transfer_monitor_cloudwatch_trigger" {
  action        = "lambda:InvokeFunction"
  function_name = module.transfer_monitor_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_monday_at_6_15.arn
}

resource "aws_cloudwatch_event_target" "event_trigger" {
  rule = aws_cloudwatch_event_rule.every_monday_at_6_15.name
  arn  = module.transfer_monitor_lambda.arn
}

