module "archivematica_dashboard_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.22.0"

  name       = "${local.dashboard_db_name}"
  identifier = "${local.dashboard_db_name}"

  allocated_storage = 10

  engine               = "mysql"
  engine_version       = "8.0.11"
  major_engine_version = "8.0"
  family               = "mysql8.0"

  instance_class = "db.t2.medium"

  backup_window      = "03:00-06:00"
  maintenance_window = "Mon:00:00-Mon:02:50"

  username = "${local.db_user}"
  password = "${local.db_user}"

  port                = "${local.db_port}"
  apply_immediately   = "true"
  create_db_instance  = "true"
  multi_az            = "true"
  publicly_accessible = "false"

  tags = {
    name = "${var.name}-archivematicadashboarddb"
  }

  vpc_security_group_ids = ["${aws_security_group.interservice_security_group.id}"]
  subnet_ids             = ["${module.archivematica_vpc.private_subnets}"]
}

module "archivematica_storage_service_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.22.0"

  name              = "${local.storage_db_name}"
  identifier        = "${local.storage_db_name}"
  allocated_storage = 10

  engine               = "mysql"
  engine_version       = "8.0.11"
  major_engine_version = "8.0"
  family               = "mysql8.0"

  instance_class = "db.t2.medium"

  backup_window      = "03:00-06:00"
  maintenance_window = "Mon:00:00-Mon:02:50"

  username = "${local.db_user}"
  password = "${local.db_user}"

  port                = "${local.db_port}"
  apply_immediately   = "true"
  create_db_instance  = "true"
  multi_az            = "true"
  publicly_accessible = "false"

  tags = {
    name = "${var.name}-archivematicstorageservicedb"
  }

  vpc_security_group_ids = ["${aws_security_group.interservice_security_group.id}"]
  subnet_ids             = ["${module.archivematica_vpc.private_subnets}"]
}

locals {
  db_user = "archivematica_db_user"
  db_pass = "archivematica_password"
  db_port = "3306"

  storage_db_endpoint = "${module.archivematica_storage_service_db.this_db_instance_endpoint}"
  storage_db_name     = "${var.name}storage"

  dashboard_db_endpoint = "${module.archivematica_dashboard_db.this_db_instance_endpoint}"
  dashboard_db_name     = "${var.name}dashboard"

  ssdb_url_storage = "mysql://${local.db_user}:${local.db_pass}@${local.storage_db_endpoint}:${local.db_port}/${local.storage_db_name}?init_command=SET sql_mode='STRICT_TRANS_TABLES'"

  ssdb_url_dashboard = "mysql://${local.db_user}:${local.db_pass}@${local.dashboard_db_endpoint}:${local.db_port}/${local.dashboard_db_name}?init_command=SET sql_mode='STRICT_TRANS_TABLES'"
}
