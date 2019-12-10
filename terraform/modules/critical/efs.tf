locals {
  efs_prod_name    = "archivematica"
  efs_staging_name = "archivematica-${var.namespace}"

  efs_name = var.namespace == "prod" ? local.efs_prod_name : local.efs_staging_name
}

data "aws_availability_zones" "available" {}

resource "aws_efs_file_system" "efs" {
  creation_token   = "archivematica_${var.namespace}_efs"
  performance_mode = "generalPurpose"

  tags = {
    # The "Name" tag is used to population the description of EFS volumes
    # in the AWS Console.
    Name = local.efs_name
  }
}

resource "aws_efs_mount_target" "mount_target" {
  count           = length(var.network_private_subnets)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.network_private_subnets[count.index]
  security_groups = [aws_security_group.efs_mnt.id]
}

resource "aws_security_group" "efs_mnt" {
  vpc_id      = var.vpc_id
  name        = "archivematica_${var.namespace}_efs_sg"

  ingress {
    protocol  = "tcp"
    from_port = 2049
    to_port   = 2049

    security_groups = [aws_security_group.efs.id]
  }
}
