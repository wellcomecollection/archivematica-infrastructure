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
  provider = "aws.routermaster"

  name = "wellcomecollection.org."
}

resource "aws_route53_record" "cert_validation" {
  provider = "aws.routermaster"
  count    = length(aws_acm_certificate.cert.domain_validation_options)

  name = aws_acm_certificate.cert.domain_validation_options[count.index].resource_record_name
  type = aws_acm_certificate.cert.domain_validation_options[count.index].resource_record_type

  records = [
    aws_acm_certificate.cert.domain_validation_options[count.index].resource_record_value
  ]

  zone_id = data.aws_route53_zone.zone.id

  ttl = 60
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn = aws_acm_certificate.cert.arn

  validation_record_fqdns = aws_route53_record.cert_validation.*.fqdn
}
