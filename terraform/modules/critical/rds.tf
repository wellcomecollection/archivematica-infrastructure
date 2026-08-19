locals {
  prod_cluster_identifier    = "archivematica-mysql8-aurora3"
  staging_cluster_identifier = "archivematica-staging"

  cluster_identifier = var.namespace == "prod" ? local.prod_cluster_identifier : local.staging_cluster_identifier

  prod_database_name    = "archivematica"
  staging_database_name = "archivematica_${var.namespace}"

  database_name = var.namespace == "prod" ? local.prod_database_name : local.staging_database_name

  instance_class = var.namespace == "prod" ? "db.r5.large" : "db.t4g.medium"

  serverlessv2_scaling_configuration = var.namespace == "prod" ? {
    max_capacity = 8
    min_capacity = 0.5
  } : null
}

resource "aws_db_subnet_group" "archivematica" {
  subnet_ids = var.network_private_subnets
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

module "aurora_rds_cluster" {
  source = "../rds"

  cluster_identifier = local.cluster_identifier
  database_name      = local.database_name
  master_username    = var.rds_username
  master_password    = var.rds_password

  db_security_group_id     = aws_security_group.database_sg.id
  aws_db_subnet_group_name = aws_db_subnet_group.archivematica.name

  snapshot_identifier = var.snapshot_identifier

  instance_class = local.instance_class

  serverlessv2_scaling_configuration = local.serverlessv2_scaling_configuration

  engine_version = "8.0.mysql_aurora.3.10.3"
}
