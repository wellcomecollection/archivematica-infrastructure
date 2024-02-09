module "critical" {
  source = "../modules/critical"

  namespace = "staging"

  providers = {
    aws              = aws
    aws.digitisation = aws.digitisation
  }

  network_private_subnets = data.terraform_remote_state.workflow.outputs.private_subnets
  vpc_id = data.terraform_remote_state.workflow.outputs.vpc_id

  rds_username = local.rds_username
  rds_password = local.rds_password

  unpacker_task_role_arn = data.terraform_remote_state.storage_service_staging.outputs.unpacker_task_role_arn

  ebs_volume_size = 100
}