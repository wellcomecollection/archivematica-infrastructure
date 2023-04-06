module "cert" {
  source = "github.com/wellcomecollection/terraform-aws-acm-certificate?ref=v1.0.0"

  domain_name = "archivematica.wellcomecollection.org"

  # The order of these names must match the order in the ACM Console, or Terraform
  # keeps trying to recreate the resource.  I'm not sure why this particular
  # ordering is favoured, or if it's arbitrary.
  subject_alternative_names = [
    "archivematica-storage-service-stage.wellcomecollection.org",
    "archivematica-stage.wellcomecollection.org",
    "archivematica-storage-service.wellcomecollection.org",
  ]

  zone_id = data.aws_route53_zone.zone.id

  providers = {
    aws.dns = aws.dns
  }
}

data "aws_route53_zone" "zone" {
  provider = aws.dns

  name = "wellcomecollection.org."
}
