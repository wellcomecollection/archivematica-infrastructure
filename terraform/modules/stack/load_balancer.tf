module "lb_dashboard" {
  source = "./load_balancer"

  name = "am-${var.namespace}-dashboard"

  vpc_id         = var.vpc_id
  public_subnets = var.network_public_subnets

  certificate_arn = var.certificate_arn

  service_lb_security_group_ids = [
    var.service_lb_security_group_id
  ]

  # We set a high timeout here and on the storage service load balancer to
  # allow Archivematica time to prepare large AIP files for download.
  # If nginx is sending back 499 responses, this may not be high enough.
  idle_timeout = 3600
}

module "lb_storage_service" {
  source = "./load_balancer"

  name = "am-${var.namespace}-storage-service"

  vpc_id         = var.vpc_id
  public_subnets = var.network_public_subnets

  certificate_arn = var.certificate_arn

  service_lb_security_group_ids = [
    var.service_lb_security_group_id
  ]

  # We set a high timeout here and on the dashboard load balancer to allow
  # Archivematica time to prepare large AIP files for download.
  # If nginx is sending back 499 responses, this may not be high enough.
  idle_timeout = 3600
}
