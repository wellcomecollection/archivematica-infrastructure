# Examples and documentation:
# https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/1.22.0
# https://github.com/terraform-aws-modules/terraform-aws-rds
# https://github.com/terraform-aws-modules/terraform-aws-rds/blob/master/examples/complete-mysql/main.tf
# https://blog.faraday.io/how-to-create-an-rds-instance-with-terraform/

# one example did the following to assign subnet ids:
//data "aws_subnet_ids" "all" {
//  vpc_id = "${data.aws_vpc.default.id}"
//}
//module "mysql_rds_db" {
//  subnet_ids = ["${data.aws_subnet_ids.all.ids}"]
//}

module "mysql_rds_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.22.0"

  name              = "archivematicadb"
  identifier        = "archivematicadb"
  allocated_storage = 10

  engine               = "mysql"
  engine_version       = "5.7.19"   # or: 8.0.11
  major_engine_version = "5.7"
  family               = "mysql5.7"

  instance_class = "db.t2.large"

  backup_window      = "03:00-06:00"
  maintenance_window = "Mon:00:00-Mon:02:50"

  # enabled_cloudwatch_logs_exports = ["audit", "general"]

  username = "archivematica_db_user"
  password = "archivematica_password"
  port     = "3306"
  apply_immediately  = "true" # migrations get applied immediately
  create_db_instance = "true"
  multi_az           = "true"
  publicly_accessible = "false"

  #db_subnet_group_name = "archivematica-db-subnet_group"
  #parameter_group_name = "archivematica-db-parameter_group"

  tags = {
    name = "archivematicadb"
  }
  vpc_security_group_ids = ["${aws_security_group.archivematica-security-group-allow-mysql.id}"]
  subnet_ids = [
    "${aws_subnet.archivematica-subnet-private1.id}",
    "${aws_subnet.archivematica-subnet-private2.id}",
  ]
}

module "archivematica_dashboard_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.22.0"

  name              = "archivematicadashboarddb"
  identifier        = "archivematicadashboarddb"
  allocated_storage = 10

  engine               = "mysql"
  engine_version       = "8.0.11"   # or: 8.0.11
  major_engine_version = "8.0"
  family               = "mysql8.0"

  instance_class = "db.t2.medium"

  backup_window      = "03:00-06:00"
  maintenance_window = "Mon:00:00-Mon:02:50"

  # enabled_cloudwatch_logs_exports = ["audit", "general"]

  username = "archivematica_db_user"
  password = "archivematica_password"
  port     = "3306"
  apply_immediately  = "true" # migrations get applied immediately
  create_db_instance = "true"
  multi_az           = "true"
  publicly_accessible = "false"

  #db_subnet_group_name = "archivematica-db-subnet_group"
  #parameter_group_name = "archivematica-db-parameter_group"

  tags = {
    name = "archivematicadashboarddb"
  }
  vpc_security_group_ids = ["${aws_security_group.archivematica-security-group-allow-mysql.id}"]
  subnet_ids = [
    "${aws_subnet.archivematica-subnet-private1.id}",
    "${aws_subnet.archivematica-subnet-private2.id}",
  ]
}

module "archivematica_storage_service_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "1.22.0"

  name              = "archivematicstorageservicedb"
  identifier        = "archivematicstorageservicedb"
  allocated_storage = 10

  engine               = "mysql"
  engine_version       = "8.0.11"   # or: 8.0.11
  major_engine_version = "8.0"
  family               = "mysql8.0"

  instance_class = "db.t2.medium"

  backup_window      = "03:00-06:00"
  maintenance_window = "Mon:00:00-Mon:02:50"

  # enabled_cloudwatch_logs_exports = ["audit", "general"]

  username = "archivematica_db_user"
  password = "archivematica_password"
  port     = "3306"
  apply_immediately  = "true" # migrations get applied immediately
  create_db_instance = "true"
  multi_az           = "true"
  publicly_accessible = "false"

  #db_subnet_group_name = "archivematica-db-subnet_group"
  #parameter_group_name = "archivematica-db-parameter_group"

  tags = {
    name = "archivematicstorageservicedb"
  }
  vpc_security_group_ids = ["${aws_security_group.archivematica-security-group-allow-mysql.id}"]
  subnet_ids = [
    "${aws_subnet.archivematica-subnet-private1.id}",
    "${aws_subnet.archivematica-subnet-private2.id}",
  ]
}

output "archivematica_dashboard_database_endpoint" {
  value = "${module.archivematica_dashboard_db.this_db_instance_endpoint}"
}

output "archivematica_storageservice_database_endpoint" {
  value = "${module.archivematica_storage_service_db.this_db_instance_endpoint}"
}

output "archivematica_database_endpoint" {
  value = "${module.mysql_rds_db.this_db_instance_endpoint}"
}
