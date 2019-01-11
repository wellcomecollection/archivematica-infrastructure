resource "aws_service_discovery_private_dns_namespace" "archivematica" {
  name = "archivematica"
  vpc  = "${local.vpc_id}"
}
