resource "aws_key_pair" "archivematica-sshkey" {
  key_name   = "archivematica-sshkey"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

resource "aws_security_group" "archivematica-security-group-allow-mysql" {
  vpc_id = "${aws_vpc.archivematica-vpc3.id}"
  name   = "archivematica-security-group-allow-mysql"

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    cidr_blocks = [
      #"0.0.0.0/0",
      "195.143.129.132/32",

      "${aws_vpc.archivematica-vpc3.cidr_block}",
    ]

    # security_groups = ["${aws_security_group.example-instance.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  tags {
    Name = "archivematica-security-group-allow-mysql"
  }
}

resource "aws_security_group" "archivematica-ecs-securitygroup" {
  vpc_id      = "${aws_vpc.archivematica-vpc3.id}"
  name        = "archivematica-ecs-securitygroup"
  description = "security group for ecs"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    #security_groups = ["${aws_security_group.myapp-elb-securitygroup.id}"]
  }

  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8002
    to_port     = 8002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8003
    to_port     = 8003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ecs"
  }
}

//resource "aws_security_group" "myapp-elb-securitygroup" {
//  vpc_id = "${aws_vpc.archivematica-vpc3.id}"
//  name = "myapp-elb"
//
//  egress {
//      from_port = 0
//      to_port = 0
//      protocol = "-1"
//      cidr_blocks = ["0.0.0.0/0"]
//  }
//
//  ingress {
//      from_port = 80
//      to_port = 80
//      protocol = "tcp"
//      cidr_blocks = ["0.0.0.0/0"]
//  }
//  tags {
//    Name = "myapp-elb"
//  }
//}

