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
