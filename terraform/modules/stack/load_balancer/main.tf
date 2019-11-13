resource "aws_alb" "load_balancer" {
  # This name can only contain alphanumerics and hyphens
  name = replace("${var.name}", "_", "-")

  subnets         = var.public_subnets
  security_groups = concat(
    var.service_lb_security_group_ids,
    list(aws_security_group.external_lb_security_group.id)
  )
  idle_timeout    = var.idle_timeout
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_alb.load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_alb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
