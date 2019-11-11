locals {
  vpc_id = "${data.terraform_remote_state.workflow.outputs.vpc_id}"

  network_private_subnets     = "${data.terraform_remote_state.workflow.outputs.private_subnets}"
  network_public_subnets      = "${data.terraform_remote_state.workflow.outputs.public_subnets}"
  network_num_private_subnets = "${data.terraform_remote_state.workflow.outputs.num_private_subnets}"

  interservice_security_group_id   = "${data.terraform_remote_state.workflow.outputs.interservice_security_group_id}"
  service_egress_security_group_id = "${data.terraform_remote_state.workflow.outputs.service_egress_security_group_id}"
  service_lb_security_group_id     = "${data.terraform_remote_state.workflow.outputs.service_lb_security_group_id}"
  efs_security_group_id            = "${data.terraform_remote_state.workflow.outputs.efs_security_group_id}"

  load_balancer_https_listener_arn = "${data.terraform_remote_state.workflow.outputs.load_balancer_https_listener_arn}"
}
