resource "aws_alb" "load_balancer" {
  # This name can only contain alphanumerics and hyphens
  name = "${replace("${var.name}", "_", "-")}"

  subnets         = ["${var.public_subnets}"]
  security_groups = ["${concat(var.service_lb_security_group_ids, list(aws_security_group.external_lb_security_group.id))}"]
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = "${aws_alb.load_balancer.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${data.aws_acm_certificate.certificate.arn}"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

data "aws_acm_certificate" "certificate" {
  domain   = "${var.certificate_domain}"
  statuses = ["ISSUED"]
}
