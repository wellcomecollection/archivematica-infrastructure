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

resource "aws_rds_cluster" "archivematica" {
  db_subnet_group_name   = aws_db_subnet_group.archivematica.name
  cluster_identifier     = local.cluster_identifier
  database_name          = local.database_name
  master_username        = var.rds_username
  master_password        = var.rds_password
  vpc_security_group_ids = [aws_security_group.database_sg.id]

  engine         = "aurora-mysql"
  engine_version = "5.7.mysql_aurora.2.11.2"
}

resource "aws_rds_cluster_instance" "archivematica" {
  count = 1

  identifier           = "${aws_rds_cluster.archivematica.cluster_identifier}-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.archivematica.id
  db_subnet_group_name = aws_db_subnet_group.archivematica.name
  publicly_accessible  = false

  # Note: right-sizing this instance has been historically tricky.
  # This is the history of our sizes, and the max connections, which has
  # traditionally been our limiting factor:
  #
  #     db.r5.large       1000
  #     db.t4g.large       135
  #     db.t4g.medium       90
  #
  # In our earliest Archivematica deployments, we needed those 1000 connections
  # even though they were mostly underused, because there was nothing in
  # between.  More recently, we've noticed Archivematica using far fewer
  # connections, and we've reduced this instance size.
  #
  # My guess is that newer versions of Archivematica are better at handling
  # database connections -- it's doing the same work with fewer connections.
  # The errors are pretty obvious if/when this goes wrong, but noting the
  # previous settings for context.
  #
  # See https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.Performance.html
  instance_class = "db.t4g.medium"

  engine         = aws_rds_cluster.archivematica.engine
  engine_version = aws_rds_cluster.archivematica.engine_version

  apply_immediately = false

  db_parameter_group_name = "default.aurora-mysql5.7"
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
