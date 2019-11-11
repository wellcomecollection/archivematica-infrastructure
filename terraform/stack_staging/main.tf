module "critical" {
  source = "../modules/stack"

  namespace = "staging"

  efs_id                = data.terraform_remote_state.critical.outputs.efs_id
  efs_security_group_id = data.terraform_remote_state.critical.outputs.efs_security_group_id

  redis_server = data.terraform_remote_state.critical.outputs.redis_server
  redis_port   = data.terraform_remote_state.critical.outputs.redis_port

  network_private_subnets = data.terraform_remote_state.workflow.outputs.private_subnets
  network_public_subnets  = data.terraform_remote_state.workflow.outputs.public_subnets
  vpc_id                  = data.terraform_remote_state.workflow.outputs.vpc_id

  interservice_security_group_id   = data.terraform_remote_state.critical.outputs.interservice_security_group_id
  service_egress_security_group_id = data.terraform_remote_state.workflow.outputs.service_egress_security_group_id
  service_lb_security_group_id     = data.terraform_remote_state.workflow.outputs.service_lb_security_group_id

  admin_cidr_ingress = local.admin_cidr_ingress

  lambda_error_alarm_arn = local.lambda_error_alarm_arn
}