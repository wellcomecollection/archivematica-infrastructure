module "lb_dashboard" {
  source = "load_balancer"

  name = "archivematica-dashboard"

  vpc_id         = "${local.vpc_id}"
  public_subnets = "${local.network_public_subnets}"

  certificate_domain = "archivematica.wellcomecollection.org"

  service_lb_security_group_ids = [
    "${local.service_lb_security_group_id}",
  ]

  lb_controlled_ingress_cidrs = ["${var.admin_cidr_ingress}"]
}

module "lb_storage_service" {
  source = "load_balancer"

  name = "archivematica-storage-service"

  vpc_id         = "${local.vpc_id}"
  public_subnets = "${local.network_public_subnets}"

  certificate_domain = "archivematica-storage-service.wellcomecollection.org"

  service_lb_security_group_ids = [
    "${local.service_lb_security_group_id}",
  ]

  lb_controlled_ingress_cidrs = ["${var.admin_cidr_ingress}"]
}
