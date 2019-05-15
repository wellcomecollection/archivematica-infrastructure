module "cluster_hosts" {
  source = "../efs"

  cluster_name = "${var.cluster_name}"
  vpc_id       = "${var.vpc_id}"

  asg_name = "${var.name}"

  ssh_ingress_security_groups = ["${module.bastion_host.ssh_controlled_ingress_sg}"]
  custom_security_groups      = ["${var.efs_security_group_ids}"]

  subnets  = "${var.private_subnets}"
  key_name = "wellcomedigitalworkflow"

  efs_fs_id = "${var.efs_id}"
  region    = "${var.region}"

  asg_min     = "${var.asg_min}"
  asg_desired = "${var.asg_desired}"
  asg_max     = "${var.asg_max}"

  instance_type = "${var.instance_type}"
}

module "bastion_host" {
  source = "git::https://github.com/wellcometrust/terraform.git//ec2/prebuilt/bastion?ref=v11.3.1"

  vpc_id = "${var.vpc_id}"

  name = "${var.name}-bastion"

  controlled_access_cidr_ingress = ["${var.controlled_access_cidr_ingress}"]

  key_name    = "${var.key_name}"
  subnet_list = "${var.public_subnets}"
}
