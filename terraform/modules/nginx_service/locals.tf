locals {
  vpc_id = "${data.terraform_remote_state.workflow.outputs.vpc_id}"

  network_private_subnets = "${data.terraform_remote_state.workflow.outputs.private_subnets}"

  interservice_security_group_id   = "${data.terraform_remote_state.workflow.outputs.interservice_security_group_id}"
  service_egress_security_group_id = "${data.terraform_remote_state.workflow.outputs.service_egress_security_group_id}"
  service_lb_security_group_id     = "${data.terraform_remote_state.workflow.outputs.service_lb_security_group_id}"

  efs_host_path = "/efs"
}
