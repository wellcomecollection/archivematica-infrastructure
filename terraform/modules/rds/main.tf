resource "aws_rds_cluster" "cluster" {
  cluster_identifier = var.cluster_identifier
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.master_password

  snapshot_identifier = var.snapshot_identifier

  engine         = "aurora-mysql"
  engine_mode    = "provisioned"
  engine_version = var.engine_version

  db_subnet_group_name   = var.aws_db_subnet_group_name
  vpc_security_group_ids = [var.db_security_group_id]

  storage_encrypted    = false
  enable_http_endpoint = false
  deletion_protection  = true

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverlessv2_scaling_configuration == null ? [] : [var.serverlessv2_scaling_configuration]

    content {
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_rds_cluster_instance" "instance" {
  cluster_identifier = aws_rds_cluster.cluster.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.cluster.engine
  engine_version     = aws_rds_cluster.cluster.engine_version
}
