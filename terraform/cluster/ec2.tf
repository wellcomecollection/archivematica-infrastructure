module "cluster_hosts" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/ec2/prebuilt/ebs?ref=v16.1.6"

  cluster_name = "${var.cluster_name}"
  vpc_id       = "${var.vpc_id}"

  asg_name = "${var.name}"

  ssh_ingress_security_groups = ["${module.bastion_host.ssh_controlled_ingress_sg}"]
  custom_security_groups      = []

  subnets  = "${var.private_subnets}"
  key_name = "${var.key_name}"

  asg_min     = "${var.asg_min}"
  asg_desired = "${var.asg_desired}"
  asg_max     = "${var.asg_max}"

  instance_type = "${var.instance_type}"
}

module "bastion_host" {
  source = "git::https://github.com/wellcometrust/terraform.git//ec2/prebuilt/bastion?ref=v16.1.6"

  vpc_id = "${var.vpc_id}"

  name = "${var.name}-bastion"

  controlled_access_cidr_ingress = ["${var.controlled_access_cidr_ingress}"]

  key_name    = "${var.key_name}"
  subnet_list = "${var.public_subnets}"
}
