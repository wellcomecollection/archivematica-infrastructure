data "aws_availability_zones" "available" {}

resource "aws_efs_file_system" "efs" {
  creation_token   = "archivematica_efs"
  performance_mode = "generalPurpose"
}

resource "aws_efs_mount_target" "mount_target" {
  count           = "${local.network_num_private_subnets}"
  file_system_id  = "${aws_efs_file_system.efs.id}"
  subnet_id       = "${local.network_private_subnets[count.index]}"
  security_groups = ["${aws_security_group.efs_mnt.id}"]
}

resource "aws_security_group" "efs_mnt" {
  description = "security groupt for efs mounts"
  vpc_id      = "${local.vpc_id}"
  name        = "archivematica_efs_sg"

  ingress {
    protocol  = "tcp"
    from_port = 2049
    to_port   = 2049

    security_groups = ["${local.efs_security_group_id}"]
  }
}
