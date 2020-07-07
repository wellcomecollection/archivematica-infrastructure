data "aws_route53_zone" "zone" {
  provider = aws.dns

  name = "wellcomecollection.org."
}

resource "aws_route53_record" "dashboard" {
  provider = aws.dns

  name = var.dashboard_hostname
  type = "CNAME"

  records = [
    module.lb_dashboard.dns_name
  ]

  zone_id = data.aws_route53_zone.zone.id

  ttl = 60
}

resource "aws_route53_record" "storage_service" {
  provider = aws.dns

  name = var.storage_service_hostname
  type = "CNAME"

  records = [
    module.lb_storage_service.dns_name
  ]

  zone_id = data.aws_route53_zone.zone.id

  ttl = 60
}
