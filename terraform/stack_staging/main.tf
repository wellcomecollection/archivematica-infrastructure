module "critical" {
  source = "../modules/stack"

  namespace = "staging"

  network_private_subnets = data.terraform_remote_state.workflow.outputs.private_subnets
  network_public_subnets  = data.terraform_remote_state.workflow.outputs.public_subnets

  vpc_id = data.terraform_remote_state.workflow.outputs.vpc_id

  admin_cidr_ingress = local.admin_cidr_ingress

  efs_id                = data.terraform_remote_state.critical.outputs.efs_id
  efs_security_group_id = data.terraform_remote_state.critical.outputs.efs_security_group_id
}