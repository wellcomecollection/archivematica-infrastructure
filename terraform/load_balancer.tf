module "lb_dashboard" {
  source = "./modules/load_balancer"

  name = "archivematica-dashboard"

  vpc_id         = "${local.vpc_id}"
  public_subnets = "${local.network_public_subnets}"

  certificate_domain = "archivematica.wellcomecollection.org"

  service_lb_security_group_ids = [
    "${local.service_lb_security_group_id}",
  ]
  idle_timeout = "3600"
}

module "lb_storage_service" {
  source = "./modules/load_balancer"

  name = "archivematica-storage-service"

  vpc_id         = "${local.vpc_id}"
  public_subnets = "${local.network_public_subnets}"

  certificate_domain = "archivematica-storage-service.wellcomecollection.org"

  service_lb_security_group_ids = [
    "${local.service_lb_security_group_id}",
  ]

  # We set a high timeout here and on the dashboard load balancer to allow
  # Archivematica time to prepare large AIP files for download
  # If nginx is sending back 499 responses, this may not be high enough.
  idle_timeout = "3600"
}
