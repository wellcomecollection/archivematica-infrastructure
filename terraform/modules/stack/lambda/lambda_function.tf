data "archive_file" "deployment_package" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.name}.zip"
}

module "lambda_function" {
  source = "github.com/wellcomecollection/terraform-aws-lambda.git?ref=v1.1.1"

  description = var.description
  name        = var.name

  filename         = data.archive_file.deployment_package.output_path
  source_code_hash = data.archive_file.deployment_package.output_base64sha256

  handler = var.handler

  runtime = "python3.8"
  timeout = var.timeout

  environment = {
    variables = var.environment
  }

  dead_letter_config = {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_alarm" {
  alarm_name          = "lambda-${var.name}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"

  dimensions = {
    FunctionName = var.name
  }

  alarm_description = "This metric monitors lambda errors for function: ${var.name}"
  alarm_actions     = [var.alarm_topic_arn]
}
