# Services in the VPC, including s3_start_transfer and any AM/SS calls to the
# public hostnames, reach the load balancers through these NAT gateways.
data "aws_nat_gateways" "vpc" {
  vpc_id = var.vpc_id

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_nat_gateway" "vpc" {
  for_each = toset(data.aws_nat_gateways.vpc.ids)
  id       = each.value
}

locals {
  alb_source_ips = concat(
    var.alb_source_ips,
    [for nat in data.aws_nat_gateway.vpc : "${nat.public_ip}/32"],
  )
}
