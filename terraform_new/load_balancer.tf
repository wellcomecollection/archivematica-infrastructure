# ALB for public services

/*

LB DRAFT 1

resource "aws_alb" "public_services" {
  # This name can only contain alphanumerics and hyphens
  name = "${replace("${local.namespace}", "_", "-")}"

  subnets         = ["${module.archivematica_vpc.public_subnets}"]
  security_groups = ["${aws_security_group.service_lb_security_group.id}", "${aws_security_group.external_lb_security_group.id}"]
}

# Listener for rest service

data "aws_lb_target_group" "target_group" {
  name = "${module.example_rest_service.target_group_name}"
}

resource "aws_alb_listener" "http_80" {
  load_balancer_arn = "${aws_alb.public_services.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${data.aws_lb_target_group.target_group.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener_rule" "path_rule_80" {
  listener_arn = "${aws_alb_listener.http_80.arn}"

  action {
    type             = "forward"
    target_group_arn = "${data.aws_lb_target_group.target_group.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/"]
  }
}

*/

/*
resource "aws_elb" "archivematica-elb" {
  name = "archivematica-elb"

  listener {
    instance_port = 8002
    instance_protocol = "http"
    lb_port = 8002
    lb_protocol = "http"
  }

  listener {
    instance_port = 8003
    instance_protocol = "http"
    lb_port = 8003
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 15
    target = "HTTP:8000/"
    interval = 60
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  subnets = [
    "${aws_subnet.archivematica-subnet-public1.id}",
    "${aws_subnet.archivematica-subnet-public2.id}"
  ]
  security_groups = ["${aws_security_group.archivematica-ecs-securitygroup.id}"]

  tags {
    Name = "archivematica-elb"
  }
}
*/