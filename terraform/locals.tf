locals {
  vpc_id = "${data.terraform_remote_state.workflow.vpc_id}"

  network_private_subnets = "${data.terraform_remote_state.workflow.private_subnets}"
  network_public_subnets  = "${data.terraform_remote_state.workflow.public_subnets}"
  network_num_private_subnets = "${data.terraform_remote_state.workflow.num_private_subnets}"

  interservice_security_group_id   = "${data.terraform_remote_state.workflow.interservice_security_group_id}"
  service_egress_security_group_id = "${data.terraform_remote_state.workflow.service_egress_security_group_id}"
  service_lb_security_group_id     = "${data.terraform_remote_state.workflow.service_lb_security_group_id}"
  efs_security_group_id            = "${data.terraform_remote_state.workflow.efs_security_group_id}"

  load_balancer_https_listener_arn = "${data.terraform_remote_state.workflow.load_balancer_https_listener_arn}"
}
