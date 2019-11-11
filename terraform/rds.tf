locals {
  rds_archivematica_url = "mysql://${local.rds_username}:${local.rds_password}@${local.rds_host}:${local.rds_port}"

  rds_host = "${aws_rds_cluster.archivematica.endpoint}"
  rds_port = "${aws_rds_cluster.archivematica.port}"
}

resource "aws_rds_cluster_instance" "archivematica" {
  count = 2

  identifier           = "archivematica-${count.index}"
  cluster_identifier   = "${aws_rds_cluster.archivematica.id}"
  instance_class       = "db.t2.small"
  db_subnet_group_name = "${aws_db_subnet_group.archivematica.name}"
  publicly_accessible  = false
}

resource "aws_db_subnet_group" "archivematica" {
  subnet_ids = "${local.network_private_subnets}"
}

resource "aws_rds_cluster" "archivematica" {
  db_subnet_group_name   = "${aws_db_subnet_group.archivematica.name}"
  cluster_identifier     = "archivematica"
  database_name          = "archivematica"
  master_username        = "${local.rds_username}"
  master_password        = "${local.rds_password}"
  vpc_security_group_ids = ["${aws_security_group.database_sg.id}"]
}

resource "aws_security_group" "database_sg" {
  vpc_id = "${local.vpc_id}"
  name   = "archivematica_sg"

  ingress {
    protocol  = "tcp"
    from_port = 3306
    to_port   = 3306

    # The database is in a private subnet, so this CIDR only gives access to
    # other instances in the private subnet (in order to reach via bastion host)
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    security_groups = ["${local.interservice_security_group_id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
