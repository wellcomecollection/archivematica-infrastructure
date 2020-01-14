locals {
  prod_ebs_name = "archivematica"
  alt_ebs_name  = "archivematica-${var.namespace}"

  ebs_name = var.namespace == "prod" ? local.prod_ebs_name : local.alt_ebs_name

  # Don't use as much EBS storage (and cost!) in the staging environment
  # as in prod.
  ebs_volume_size = var.namespace == "prod" ? 750 : 250
}

resource "aws_ebs_volume" "ebs" {
  availability_zone = "eu-west-1a"
  size              = local.ebs_volume_size

  tags = {
    Name = local.ebs_name
  }
}
