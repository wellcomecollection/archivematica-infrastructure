module "cluster" {
  source = "cluster"

  name = "archivematica"

  vpc_id          = "${local.vpc_id}"
  public_subnets  = "${local.network_public_subnets}"
  private_subnets = "${local.network_private_subnets}"

  region   = "${var.region}"
  key_name = "wellcomedigitalworkflow"

  controlled_access_cidr_ingress = ["${var.controlled_access_cidr_ingress}"]

  efs_security_group_ids = ["${local.efs_security_group_id}"]
  efs_id                 = "${module.efs.efs_id}"

  cluster_name = "${aws_ecs_cluster.archivematica.name}"

  asg_min     = 1
  asg_desired = 2
  asg_max     = 2

  instance_type = "t2.large"

  ebs_size = 50
}
