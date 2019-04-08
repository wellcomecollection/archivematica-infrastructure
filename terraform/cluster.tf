module "cluster" {
  source = "cluster"

  name = "archivematica"

  vpc_id          = "${local.vpc_id}"
  public_subnets  = "${local.network_public_subnets}"
  private_subnets = "${local.network_private_subnets}"

  region   = "${var.region}"
  key_name = "wellcomedigitalworkflow"

  controlled_access_cidr_ingress = ["${local.admin_cidr_ingress}"]

  efs_security_group_ids = ["${local.efs_security_group_id}"]
  efs_id                 = "${module.efs.efs_id}"

  cluster_name = "${aws_ecs_cluster.archivematica.name}"

  asg_min     = 1
  asg_desired = 1
  asg_max     = 1

  # The constraint here isn't CPU or memory; it's Elastic Network Interfaces.
  instance_type = "c5.4xlarge"
}
