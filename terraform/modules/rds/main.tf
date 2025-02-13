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
  enable_http_endpoint = true
  deletion_protection  = true

  serverlessv2_scaling_configuration {
    max_capacity = var.max_scaling_capacity
    min_capacity = var.min_scaling_capacity
  }
}

resource "aws_rds_cluster_instance" "migration_instance" {
  cluster_identifier = aws_rds_cluster.cluster.id
  instance_class     = var.migration_instance_class
  engine             = aws_rds_cluster.cluster.engine
  engine_version     = aws_rds_cluster.cluster.engine_version
}

# NOTE: This can be uncommented during serverless migration
# resource "aws_rds_cluster_instance" "serverless_instance" {
#   cluster_identifier = aws_rds_cluster.cluster.id
#   instance_class     = "db.serverless"
#   engine             = aws_rds_cluster.cluster.engine
#   engine_version     = aws_rds_cluster.cluster.engine_version
# }