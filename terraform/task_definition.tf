module "log_group" {
  source = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/log_group?ref=v17.1.0"

  task_name = "archivematica"
}

data "template_file" "container_definitions" {
  template = "${file("container_definitions.json")}"

  vars {
    dashboard_image       = "${module.ecr_dashboard.repository_url}:${var.release_ids["archivematica_dashboard"]}",
    mcp_client_image      = "${module.ecr_mcp_client.repository_url}:${var.release_ids["archivematica_mcp_client"]}"
    mcp_server_image      = "${module.ecr_mcp_server.repository_url}:${var.release_ids["archivematica_mcp_server"]}"
    nginx_image           = "${module.ecr_nginx.repository_url}:${var.release_ids["archivematica_nginx"]}"
    storage_service_image = "${module.ecr_storage_service.repository_url}:${var.release_ids["archivematica_storage_service"]}"

    log_group_region = "${var.region}"
    log_group_name   = "${module.log_group.name}"
    log_group_prefix = "archivematica"

    rds_username = "${module.rds_cluster.username}"
    rds_password = "${module.rds_cluster.password}"
    rds_host     = "${module.rds_cluster.host}"
    rds_port     = "${module.rds_cluster.port}"

    redis_server = "${aws_elasticache_cluster.archivematica.cache_nodes.0.address}"
    redis_port   = "${aws_elasticache_cluster.archivematica.cache_nodes.0.port}"

    elasticsearch_endpoint = "${aws_elasticsearch_domain.archivematica.endpoint}"

    efs_mount_path = "${local.efs_host_path}"
  }
}

resource "aws_ecs_cluster" "archivematica" {
  name = "archivematica"
}

module "iam_roles" {
  source = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/iam_roles?ref=v17.1.0"

  task_name = "archivematica"
}

locals {
  efs_host_path = "/efs"
}

resource "aws_ecs_task_definition" "archivematica" {
  family                = "archivematica"
  container_definitions = "${data.template_file.container_definitions.rendered}"
  execution_role_arn    = "${module.iam_roles.task_execution_role_arn}"

  network_mode = "awsvpc"

  # For now, using EBS/EFS means we need to be on EC2 instance.
  requires_compatibilities = ["EC2"]

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:efs.volume exists"
  }

  volume {
    name      = "location-data"
    host_path = "${local.efs_host_path}/location-data"
  }

  volume {
    name      = "pipeline-data"
    host_path = "${local.efs_host_path}/pipeline-data"
  }

  volume {
    name      = "staging-data"
    host_path = "${local.efs_host_path}/staging-data"
  }

  cpu    = 2048
  memory = 5120
}

resource "aws_alb_listener_rule" "https" {
  listener_arn = "${module.load_balancer.https_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${module.service.target_group_arn}"
  }

  condition {
    field  = "host-header"
    values = ["archivematica.wellcomecollection.org"]
  }
}

module "service" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/service/prebuilt/load_balanced?ref=v11.3.1"

  service_name       = "archivematica-dashboard"
  task_desired_count = 1

  # The root paths return 302s which redirect to this login page.
  healthcheck_path = "/administration/accounts/login/"

  task_definition_arn = "${aws_ecs_task_definition.archivematica.arn}"

  security_group_ids = [
    "${local.interservice_security_group_id}",
    "${local.service_egress_security_group_id}",
    "${local.service_lb_security_group_id}",
  ]

  container_name = "nginx"
  container_port = 9090

  ecs_cluster_id = "${aws_ecs_cluster.archivematica.id}"

  vpc_id  = "${local.vpc_id}"
  subnets = "${local.network_private_subnets}"

  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"

  launch_type = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200
}

module "storage_service" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/service/prebuilt/load_balanced?ref=v11.3.1"

  service_name       = "archivematica-storage-service"
  task_desired_count = 1

  healthcheck_path = "/login/"

  task_definition_arn = "${aws_ecs_task_definition.archivematica.arn}"

  security_group_ids = [
    "${local.interservice_security_group_id}",
    "${local.service_egress_security_group_id}",
    "${local.service_lb_security_group_id}",
  ]

  container_name = "nginx"
  container_port = 8080

  ecs_cluster_id = "${aws_ecs_cluster.archivematica.id}"

  vpc_id  = "${local.vpc_id}"
  subnets = "${local.network_private_subnets}"

  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"

  launch_type = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200
}

resource "aws_alb_listener_rule" "storage_service_https" {
  listener_arn = "${module.load_balancer_storage_service.https_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${module.storage_service.target_group_arn}"
  }

  condition {
    field  = "host-header"
    values = ["archivematica-storage-service.wellcomecollection.org"]
  }
}