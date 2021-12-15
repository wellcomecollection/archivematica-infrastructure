resource "aws_acm_certificate" "cert" {
  domain_name       = "archivematica.wellcomecollection.org"
  validation_method = "DNS"

  # The order of these names must match the order in the ACM Console, or Terraform
  # keeps trying to recreate the resource.  I'm not sure why this particular
  # ordering is favoured, or if it's arbitrary.
  subject_alternative_names = [
    "archivematica-storage-service-stage.wellcomecollection.org",
    "archivematica-stage.wellcomecollection.org",
    "archivematica-storage-service.wellcomecollection.org",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "zone" {
  provider = aws.dns

  name = "wellcomecollection.org."
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.dns

  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name = each.value.name
  type = each.value.type

  records = [
    each.value.record
  ]

  zone_id = data.aws_route53_zone.zone.id

  ttl = 60
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn = aws_acm_certificate.cert.arn

  validation_record_fqdns = toset([
    for cv in aws_route53_record.cert_validation : cv.fqdn
  ])
}
