module "cluster" {
  source = "cluster"

  name = "${var.name}"

  vpc_id = "${module.archivematica_vpc.vpc_id}"

  public_subnets  = "${module.archivematica_vpc.public_subnets}"
  private_subnets = "${module.archivematica_vpc.private_subnets}"

  key_name = "${var.key_name}"

  controlled_access_cidr_ingress = ["${var.controlled_access_cidr_ingress}"]

  cluster_name = "${aws_ecs_cluster.archivematica.name}"

  asg_min     = "${var.asg_min}"
  asg_desired = "${var.asg_desired}"
  asg_max     = "${var.asg_max}"

  instance_type = "${var.instance_type}"
}

module "dashboard" {
  source = "dashboard"

  cpu    = "1024"
  memory = "2048"

  ebs_container_path = "/ebs_volume"
  ebs_host_path      = "/mnt/ebs"

  app_cpu      = "512"
  app_memory   = "1024"
  app_env_vars = {}

  app_container_image = "strm/helloworld-http"
  app_container_port  = "80"

  sidecar_cpu      = "512"
  sidecar_memory   = "1024"
  sidecar_env_vars = {}

  sidecar_container_image = "760097843905.dkr.ecr.eu-west-1.amazonaws.com/uk.ac.wellcome/nginx_api-gw:bad0dbfa548874938d16496e313b05adb71268b7"
  sidecar_container_port  = "9000"

  name       = "${var.name}-dashboard"
  vpc_id     = "${module.archivematica_vpc.vpc_id}"
  aws_region = "${var.aws_region}"

  cluster_id       = "${aws_ecs_cluster.archivematica.id}"
  namespace_id     = "${aws_service_discovery_private_dns_namespace.namespace.id}"
  log_group_prefix = "am"

  lb_arn = "${aws_alb.loris.arn}"

  private_subnets = "${module.archivematica_vpc.private_subnets}"

  healthcheck_path = "/"

  security_group_ids = [
    "${aws_security_group.service_egress_security_group.id}",
    "${aws_security_group.service_lb_security_group.id}",
  ]
}
