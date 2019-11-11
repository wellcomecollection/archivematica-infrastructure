module "cluster" {
  source = "./cluster"

  name = "archivematica-${var.namespace}"

  vpc_id          = var.vpc_id
  public_subnets  = var.network_public_subnets
  private_subnets = var.network_private_subnets

  region   = var.aws_region
  key_name = "wellcomedigitalworkflow"

  controlled_access_cidr_ingress = var.admin_cidr_ingress

  efs_security_group_ids = [var.efs_security_group_id]
  efs_id                 = var.efs_id

  cluster_name = "${aws_ecs_cluster.archivematica.name}"

  asg_min     = 3
  asg_desired = 3
  asg_max     = 3

  # The constraint here isn't CPU or memory; it's Elastic Network Interfaces.
  instance_type = "t2.xlarge"
}
