module "rds_cluster" {
  source             = "git::https://github.com/wellcometrust/terraform.git//rds?ref=v13.0.0"
  cluster_identifier = "archivematica"
  database_name      = "archivematica"
  username           = "${local.rds_username}"
  password           = "${local.rds_password}"
  vpc_subnet_ids     = "${local.network_private_subnets}"
  vpc_id             = "${local.vpc_id}"

  # The database is in a private subnet, so this CIDR only gives access to
  # other instances in the private subnet (in order to reach via bastion host)
  admin_cidr_ingress = "0.0.0.0/0"

  db_access_security_group = ["${local.interservice_security_group_id}"]

  vpc_security_group_ids = "${local.interservice_security_group_id}"
}
