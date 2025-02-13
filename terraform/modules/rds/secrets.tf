module "secrets" {
  source = "github.com/wellcomecollection/terraform-aws-secrets.git?ref=v1.2.0"

  key_value_map = {
    "rds/${var.cluster_identifier}/endpoint"        = aws_rds_cluster.cluster.endpoint
    "rds/${var.cluster_identifier}/reader_endpoint" = aws_rds_cluster.cluster.reader_endpoint
    "rds/${var.cluster_identifier}/port"            = aws_rds_cluster.cluster.port
  }
}

variable "engine_version" {
  type = string
}
