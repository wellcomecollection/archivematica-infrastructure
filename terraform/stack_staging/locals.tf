locals {
  lambda_error_alarm_arn = data.terraform_remote_state.shared_infra.outputs.lambda_error_alarm_arn
  ecr_storage_service_repo_url = data.terraform_remote_state.shared_archivematica.outputs.ecr_storage_service_repo_url
}
