locals {
  network_private_subnets = "${data.terraform_remote_state.workflow.private_subnets}"

  interservice_security_group_id   = "${data.terraform_remote_state.workflow.interservice_security_group_id}"
  service_egress_security_group_id = "${data.terraform_remote_state.workflow.service_egress_security_group_id}"
  service_lb_security_group_id     = "${data.terraform_remote_state.workflow.service_lb_security_group_id}"

  efs_host_path = "/efs"
}
