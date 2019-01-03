resource "aws_security_group" "external_lb_security_group" {
  name        = "${var.name}_external_lb_security_group"
  description = "Allow traffic between load balancer and internet"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    cidr_blocks = ["${var.lb_controlled_ingress_cidrs}"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443

    cidr_blocks = ["${var.lb_controlled_ingress_cidrs}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-external-lb"
  }
}
