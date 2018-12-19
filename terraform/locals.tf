locals {
  vpc_id = "${data.terraform_remote_state.workflow.vpc_id}"

  network_private_subnets = "${data.terraform_remote_state.workflow.private_subnets}"
  network_public_subnets  = "${data.terraform_remote_state.workflow.public_subnets}"
  network_num_private_subnets = "${data.terraform_remote_state.workflow.num_private_subnets}"

  efs_security_group_id = "${data.terraform_remote_state.workflow.efs_security_group_id}"
}
