module "storage_stage_listener" {
  source = "./listener"

  environment = "staging"
  input_topic = local.storage_staging_outputs["registered_bag_notifications_topic_arn"]

  lambda_error_alarm_arn = local.lambda_error_alarm_arn
  dlq_alarm_arn          = local.dlq_alarm_arn

  providers = {
    aws          = aws
    aws.digirati = aws.digirati
  }
}

module "storage_prod_listener" {
  source = "./listener"

  environment = "prod"
  input_topic = local.storage_prod_outputs["registered_bag_notifications_topic_arn"]

  lambda_error_alarm_arn = local.lambda_error_alarm_arn
  dlq_alarm_arn          = local.dlq_alarm_arn

  providers = {
    aws          = aws
    aws.digirati = aws.digirati
  }
}
