locals {
  prod_ebs_name = "archivematica"
  alt_ebs_name  = "archivematica-${var.namespace}"

  ebs_name = var.namespace == "prod" ? local.prod_ebs_name : local.alt_ebs_name

  ebs_volume_size = var.ebs_volume_size
}

resource "aws_ebs_volume" "ebs" {
  availability_zone = "eu-west-1a"
  size              = local.ebs_volume_size

  type = "gp3"

  tags = {
    Name = local.ebs_name
  }
}
