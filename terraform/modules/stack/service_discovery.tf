resource "aws_service_discovery_private_dns_namespace" "archivematica" {
  name = "archivematica-${var.namespace}"
  vpc  = var.vpc_id
}
