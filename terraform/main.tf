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
  source = "public_service"

  cpu    = "1024"
  memory = "2048"

  ebs_container_path = "/var/archivematica/sharedDirectory"
  ebs_host_path      = "/mnt/ebs"

  app_cpu    = "512"
  app_memory = "1024"

  app_env_vars = {
    SS_DB_URL          = "${local.ssdb_url_dashboard}"
    DJANGO_PORT        = "80"
    DJANGO_STATIC_ROOT = "/data/archivematica/dashboard-static"
  }

  app_env_vars_length = "2"

  app_container_image = "${aws_ecr_repository.archivematica-ecr-dashboard-repository.repository_url}:${var.release_ids["archivematica_dashboard"]}"
  app_container_port  = "80"

  sidecar_cpu    = "512"
  sidecar_memory = "1024"

  sidecar_env_vars = {
    APP_HOST = "localhost"
    APP_PORT = "80"
  }

  sidecar_env_vars_length = "3"

  sidecar_container_image = "${var.nginx_container_image}"
  sidecar_container_port  = "9000"

  name       = "${var.name}-dashboard"
  vpc_id     = "${module.archivematica_vpc.vpc_id}"
  aws_region = "${var.aws_region}"

  cluster_id       = "${aws_ecs_cluster.archivematica.id}"
  namespace_id     = "${aws_service_discovery_private_dns_namespace.namespace.id}"
  log_group_prefix = "am"

  lb_arn = "${aws_alb.archivematica.arn}"

  private_subnets = "${module.archivematica_vpc.private_subnets}"

  healthcheck_path = "/"

  security_group_ids = [
    "${aws_security_group.interservice_security_group.id}",
    "${aws_security_group.service_egress_security_group.id}",
    "${aws_security_group.service_lb_security_group.id}",
  ]
}

module "storage" {
  source = "private_service"

  cpu    = "512"
  memory = "1028"

  ebs_container_path = "/var/archivematica/sharedDirectory"
  ebs_host_path      = "/mnt/ebs"

  env_vars = {
    SS_DB_URL = "${local.ssdb_url_storage}"
  }

  env_vars_length = "1"

  container_image = "${aws_ecr_repository.archivematica-ecr-storage-service-repository.repository_url}:1.07"
  container_port  = "8003"

  name       = "${var.name}-storage"
  vpc_id     = "${module.archivematica_vpc.vpc_id}"
  aws_region = "${var.aws_region}"

  cluster_id       = "${aws_ecs_cluster.archivematica.id}"
  namespace_id     = "${aws_service_discovery_private_dns_namespace.namespace.id}"
  log_group_prefix = "am"

  lb_arn = "${aws_alb.archivematica.arn}"

  private_subnets = "${module.archivematica_vpc.private_subnets}"

  healthcheck_path = "/"

  security_group_ids = [
    "${aws_security_group.service_egress_security_group.id}",
    "${aws_security_group.interservice_security_group.id}",
  ]
}
