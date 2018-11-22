resource "aws_alb" "loris" {
  # This name can only contain alphanumerics and hyphens
  name = "${replace("${var.name}", "_", "-")}"

  subnets         = ["${module.archivematica_vpc.public_subnets}"]
  security_groups = ["${aws_security_group.service_lb_security_group.id}", "${aws_security_group.external_lb_security_group.id}"]
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = "${aws_alb.loris.id}"
  port              = "${var.listener_port}"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${data.aws_acm_certificate.certificate.arn}"

  default_action {
    type = "redirect"

    redirect {
      host        = "developers.wellcomecollection.org"
      path        = "/iiif"
      status_code = "HTTP_301"
    }
  }
}

data "aws_acm_certificate" "certificate" {
  domain   = "${var.certificate_domain}"
  statuses = ["ISSUED"]
}
