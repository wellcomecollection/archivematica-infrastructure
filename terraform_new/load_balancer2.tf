
/*

LB DRAFT 2

resource "aws_alb" "archivematica" {
  # This name can only contain alphanumerics and hyphens
  name = "${replace("${var.namespace}", "_", "-")}"

  subnets         = ["${module.archivematica_vpc.public_subnets}"]
  security_groups = ["${aws_security_group.service_lb_security_group.id}", "${aws_security_group.external_lb_security_group.id}"]
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = "${aws_alb.archivematica.id}"
  port              = "${local.dashboard_public_port}"
  #protocol          = "HTTPS"
  #ssl_policy        = "ELBSecurityPolicy-2015-05"
  # certificate_arn   = "${data.aws_acm_certificate.certificate.arn}"

  default_action {
    type = "forward"
    target_group_arn = "${data.aws_lb_target_group.archivematica.arn}"
  }
}

resource "aws_alb_target_group" "archivematica-dashboard" {
  name = "archivematica-dashboard"
  port = 80
  protocol = "HTTP"
  vpc_id = "${module.archivematica_vpc.vpc_id}"
}


resource "aws_alb_listener" "dashboard-listener" {
  load_balancer_arn = "${aws_alb.archivematica.arn}"
  port = "${local.dashboard_public_port}"
}

data "aws_lb_target_group" "archivematica" {
  name = "${module.service.target_group_name}"
}

resource "aws_alb_listener_rule" "https" {
  listener_arn = "${aws_alb_listener.https.arn}"

  action {
    type             = "forward"
    target_group_arn = "${data.aws_lb_target_group.archivematica.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/image/*"]
  }
}

data "aws_acm_certificate" "certificate" {
  domain   = "${var.certificate_domain}"
  statuses = ["ISSUED"]
}
*/