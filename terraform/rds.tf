module "rds_cluster" {
  source             = "git::https://github.com/wellcometrust/terraform.git//rds?ref=v13.0.0"
  cluster_identifier = "archivematica"
  database_name      = "archivematica"
  username           = "${var.rds_username}"
  password           = "${var.rds_password}"
  vpc_subnet_ids     = "${local.network_private_subnets}"
  vpc_id             = "${local.vpc_id}"
  admin_cidr_ingress = "${var.rds_admin_cidr_ingress}"

  db_access_security_group = ["${aws_security_group.rds_ingress_security_group.id}"]

  vpc_security_group_ids = []
}

resource "aws_security_group" "rds_ingress_security_group" {
  name   = "archivematica_rds_ingress_security_group"
  vpc_id = "${local.vpc_id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}
