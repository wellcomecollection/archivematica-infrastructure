module "lambda" {
  source = "../lambda"

  name        = "born-digital-listener-${var.environment}"
  filename    = "${path.module}/../born_digital_listener.py"
  handler     = "born_digital_listener.handler"
  description = "Listens for new born-digital bags and forwards them to DLCS"

  environment = {
    SNS_TOPIC = module.output_sns_topic.arn
  }

  alarm_topic_arn = var.lambda_error_alarm_arn
}

resource "aws_lambda_permission" "allow_sns_to_trigger_lambda" {
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.input_topic
  depends_on    = [aws_sns_topic_subscription.lambda]
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = var.input_topic
  protocol  = "lambda"
  endpoint  = module.lambda.arn
}

module "output_sns_topic" {
  source = "github.com/wellcomecollection/terraform-aws-sns-topic.git?ref=v1.0.1"
  name   = "born-digital-bag-notifications-${var.environment}"

  cross_account_subscription_ids = [
    "653428163053",
  ]
}

module "output_sqs_queue" {
  source     = "git::github.com/wellcomecollection/terraform-aws-sqs//queue?ref=v1.2.1"
  queue_name = "born-digital-notifications-${var.environment}"
  topic_arns = [module.output_sns_topic.arn]

  alarm_topic_arn = var.dlq_alarm_arn
}

module "output_sqs_queue_digirati" {
  source     = "git::github.com/wellcomecollection/terraform-aws-sqs//queue?ref=v1.2.1"
  queue_name = "born-digital-notifications-${var.environment}"
  topic_arns = [module.output_sns_topic.arn]

  alarm_topic_arn = var.dlq_alarm_arn

  providers = {
    aws = aws.digirati
  }
}

resource "aws_iam_role_policy" "allow_lambda_to_publish_to_sns" {
  role   = module.lambda.role_name
  policy = module.output_sns_topic.publish_policy
}
