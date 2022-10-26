data "archive_file" "deployment_package" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${var.name}.zip"
}

resource "aws_lambda_function" "lambda_function" {
  description   = var.description
  function_name = var.name

  filename         = data.archive_file.deployment_package.output_path
  source_code_hash = data.archive_file.deployment_package.output_base64sha256

  handler = var.handler

  role    = aws_iam_role.iam_role.arn
  runtime = "python3.8"
  timeout = var.timeout

  environment {
    variables = var.environment
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

resource "aws_iam_role_policy_attachment" "basic_execution_role" {
  role       = aws_iam_role.iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
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
