module "archivematica_vpc" {
  source = "github.com/wellcometrust/terraform-modules//network/prebuilt/vpc/public-private-igw?ref=v16.1.6"

  name = "archivematica-172-29-0-0-16"

  cidr_block_vpc = "172.29.0.0/16"

  cidr_block_public         = "172.29.0.0/17"
  cidrsubnet_newbits_public = "2"

  cidr_block_private         = "172.29.128.0/17"
  cidrsubnet_newbits_private = "2"
}

resource "aws_ecs_cluster" "archivematica" {
  name = "${var.name}"
}

resource "aws_service_discovery_private_dns_namespace" "namespace" {
  name = "${var.name}"
  vpc  = "${module.archivematica_vpc.vpc_id}"
}
