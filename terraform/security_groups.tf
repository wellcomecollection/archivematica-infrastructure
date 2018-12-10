resource "aws_security_group" "service_lb_security_group" {
  name        = "${var.name}_service_lb_security_group"
  description = "Allow traffic between services and load balancer"
  vpc_id      = "${module.archivematica_vpc.vpc_id}"

  ingress {
    protocol  = "tcp"
    from_port = 9000
    to_port   = 9000
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-service-lb"
  }
}

resource "aws_security_group" "external_lb_security_group" {
  name        = "${var.name}_external_lb_security_group"
  description = "Allow traffic between load balancer and internet"
  vpc_id      = "${module.archivematica_vpc.vpc_id}"

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443

    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group" "service_egress_security_group" {
  name        = "${var.name}_service_egress_security_group"
  description = "Allow traffic between services"
  vpc_id      = "${module.archivematica_vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-egress"
  }
}

resource "aws_security_group" "interservice_security_group" {
  name        = "${var.name}_interservice_security_group"
  description = "Allow traffic between services"
  vpc_id      = "${module.archivematica_vpc.vpc_id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  tags {
    Name = "${var.name}-interservice"
  }
}