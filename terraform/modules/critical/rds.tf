locals {
  rds_archivematica_url = "mysql://${var.rds_username}:${var.rds_password}@${local.rds_host}:${local.rds_port}"

  rds_host = aws_rds_cluster.archivematica.endpoint
  rds_port = aws_rds_cluster.archivematica.port

  prod_cluster_identifier    = "archivematica"
  staging_cluster_identifier = "archivematica-${var.namespace}"

  cluster_identifier = var.namespace == "prod" ? local.prod_cluster_identifier : local.staging_cluster_identifier

  prod_database_name    = "archivematica"
  staging_database_name = "archivematica_${var.namespace}"

  database_name = var.namespace == "prod" ? local.prod_database_name : local.staging_database_name
}

resource "aws_db_subnet_group" "archivematica" {
  subnet_ids = var.network_private_subnets
}

# This tweaks the MySQL settings to make Archivematica happier with transfers
# that contain lots of files.
#
# We don't set it as high as 1GB, because if we set it too high all transfers
# start to slow down -- but it's higher than the Aurora default, which is 4MB.
#
# See https://github.com/archivematica/Issues/issues/956
#     https://github.com/wellcomecollection/platform/issues/4233
#
resource "aws_db_parameter_group" "archivematica" {
  name   = "archivematica-${var.namespace}"
  family = "aurora5.6"

  parameter {
    apply_method = "pending-reboot"
    name         = "max_allowed_packet"
    value        = 100 * 1024 * 1024
  }
}

resource "aws_rds_cluster" "archivematica" {
  db_subnet_group_name   = aws_db_subnet_group.archivematica.name
  cluster_identifier     = local.cluster_identifier
  database_name          = local.database_name
  master_username        = var.rds_username
  master_password        = var.rds_password
  vpc_security_group_ids = [aws_security_group.database_sg.id]

  # Be careful of changing these.  When I tried updating to MySQL 5.7
  # (or a different flavour of 5.6), transfers would always fail at
  # the "Scan for viruses" stage.
  #
  # Debugging showed that we were getting a repeated error inside
  # the MCP client:
  #
  #     OperationalError: (2006, 'MySQL server has gone away')
  #
  # It could connect to the database if you opened an interactive shell,
  # but something in the Archivematica process kept breaking.
  #
  # We should diagnose this further and understand why Archivematica
  # doesn't work with MySQL 5.7, but I don't want to do that right now.
  #
  # Possibly related:
  # https://www.archivematica.org/en/docs/archivematica-1.10/admin-manual/installation-setup/installation/installation/#dependencies
  engine         = "aurora"
  engine_version = "5.6.mysql_aurora.1.22.2"
}

resource "aws_rds_cluster_instance" "archivematica" {
  count = 1

  identifier           = "${aws_rds_cluster.archivematica.cluster_identifier}-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.archivematica.id
  instance_class       = var.namespace == "prod" ? "db.r5.large" : "db.t3.medium"
  db_subnet_group_name = aws_db_subnet_group.archivematica.name
  publicly_accessible  = false

  engine         = aws_rds_cluster.archivematica.engine
  engine_version = aws_rds_cluster.archivematica.engine_version

  apply_immediately = false

  db_parameter_group_name = aws_db_parameter_group.archivematica.name
}

resource "aws_security_group" "database_sg" {
  vpc_id = var.vpc_id
  name   = "archivematica_${var.namespace}_db_sg"

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

    security_groups = [aws_security_group.interservice.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
