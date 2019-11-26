locals {
  rds_archivematica_url = "mysql://${var.rds_username}:${var.rds_password}@${local.rds_host}:${local.rds_port}"

  rds_host = aws_rds_cluster.archivematica.endpoint
  rds_port = aws_rds_cluster.archivematica.port
}

resource "aws_rds_cluster_instance" "archivematica" {
  count = 4

  identifier           = "archivematica-${var.namespace}-${count.index}"
  cluster_identifier   = aws_rds_cluster.archivematica.id
  instance_class       = "db.t2.small"
  db_subnet_group_name = aws_db_subnet_group.archivematica.name
  publicly_accessible  = false
}

resource "aws_db_subnet_group" "archivematica" {
  subnet_ids = var.network_private_subnets
}

resource "aws_rds_cluster" "archivematica" {
  db_subnet_group_name   = aws_db_subnet_group.archivematica.name
  cluster_identifier     = "archivematica-${var.namespace}"
  database_name          = "archivematica_${var.namespace}"
  master_username        = var.rds_username
  master_password        = var.rds_password
  vpc_security_group_ids = [aws_security_group.database_sg.id]
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
