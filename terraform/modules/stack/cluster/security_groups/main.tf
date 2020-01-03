resource "aws_security_group" "ssh_controlled_ingress" {
  vpc_id      = var.vpc_id
  name        = "${var.name}_ssh_controlled_ingress_${random_id.sg_append.hex}"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = var.controlled_access_cidr_ingress
    security_groups = var.controlled_access_security_groups
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "full_egress" {
  vpc_id = var.vpc_id
  name   = "${var.name}_full_egress_${random_id.sg_append.hex}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_id" "sg_append" {
  keepers = {
    sg_id = var.name
  }

  byte_length = 8
}
