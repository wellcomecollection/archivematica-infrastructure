module "load_balancer" {
  source = "load_balancer"

  name = "archivematica"

  vpc_id         = "${local.vpc_id}"
  public_subnets = "${local.network_public_subnets}"

  certificate_domain = "archivematica.wellcomecollection.org"

  service_lb_security_group_ids = [
    "${local.service_lb_security_group_id}",
  ]

  lb_controlled_ingress_cidrs = ["${var.admin_cidr_ingress}"]
}
