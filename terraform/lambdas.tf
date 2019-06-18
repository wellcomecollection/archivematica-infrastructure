module "s3_starttransfer_lambda" {
  source      = "git::https://github.com/wellcometrust/terraform.git//lambda?ref=v1.0.3"
  s3_bucket   = "wellcomecollection-workflow-infra"
  s3_key      = "lambdas/archivematica/s3_starttransfer.zip"
  module_name = "starttransfer"

  description     = "Start new Archivematica transfers for uploads to transfer bucket"
  name            = "s3_starttransfer"
  alarm_topic_arn = "${data.terraform_remote_state.shared_infra.lambda_error_alarm_arn}"
  environment_variables = {
    "ARCHIVEMATICA_URL" = "https://${module.dashboard_service.hostname}"
    "ARCHIVEMATICA_SS_URL" = "https://${module.storage_service.hostname}"
    "ARCHIVEMATICA_USERNAME" = "${local.archivematica_username}"
    "ARCHIVEMATICA_API_KEY" = "${local.archivematica_api_key}"
    "ARCHIVEMATICA_SS_USERNAME" = "${local.archivematica_ss_username}"
    "ARCHIVEMATICA_SS_API_KEY" = "${local.archivematica_ss_api_key}"
  }

  timeout = 120
}

resource "aws_lambda_permission" "allow_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket_${module.s3_starttransfer_lambda.function_name}"
  action        = "lambda:InvokeFunction"
  function_name = "${module.s3_starttransfer_lambda.function_name}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.archivematica_transfer.arn}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket    = "${aws_s3_bucket.archivematica_transfer.id}"

  lambda_function {
    lambda_function_arn = "${module.s3_starttransfer_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "test-uploads/"
    filter_suffix       = ""
  }
}
