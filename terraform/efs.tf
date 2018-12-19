module "efs" {
  source = "git::https://github.com/wellcometrust/terraform.git//efs?ref=v11.4.0"

  name = "archivematica"

  vpc_id  = "${local.vpc_id}"
  subnets = "${local.network_private_subnets}"

  num_subnets = "${local.network_num_private_subnets}"

  efs_access_security_group_ids = ["${local.efs_security_group_id}"]
}
