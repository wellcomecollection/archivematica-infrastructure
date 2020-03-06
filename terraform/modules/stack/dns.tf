data "aws_route53_zone" "zone" {
  provider = aws.routermaster

  name = "wellcomecollection.org."
}

resource "aws_route53_record" "dashboard" {
  provider = aws.routermaster

  name = var.dashboard_hostname
  type = "CNAME"

  records = [
    module.lb_dashboard.dns_name
  ]

  zone_id = data.aws_route53_zone.zone.id

  ttl = 60
}

resource "aws_route53_record" "storage_service" {
  provider = aws.routermaster

  name = var.storage_service_hostname
  type = "CNAME"

  records = [
    module.lb_storage_service.dns_name
  ]

  zone_id = data.aws_route53_zone.zone.id

  ttl = 60
}

provider "aws" {
  region  = "eu-west-1"
  version = "2.35.0"
  alias   = "routermaster"

  assume_role {
    role_arn = "arn:aws:iam::250790015188:role/wellcomecollection-assume_role_hosted_zone_update"
  }
}
