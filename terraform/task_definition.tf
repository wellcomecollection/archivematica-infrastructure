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
  }
}

resource "aws_ecs_cluster" "archivematica" {
  name = "archivematica"
}

module "iam_roles" {
  source = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/iam_roles?ref=v17.1.0"

  task_name = "archivematica"
}

resource "aws_ecs_task_definition" "archivematica" {
  family                = "archivematica"
  container_definitions = "${data.template_file.container_definitions.rendered}"
  execution_role_arn    = "${module.iam_roles.task_execution_role_arn}"

  network_mode = "awsvpc"

  volume {
    name = "pipeline-data"
  }

  volume {
    name = "location-data"
  }

  volume {
    name = "staging-data"
  }

  requires_compatibilities = ["EC2"]

  cpu    = 2048
  memory = 5120
}

resource "aws_service_discovery_private_dns_namespace" "archivematica" {
  name = "archivematica"
  vpc  = "${local.vpc_id}"
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

  service_name       = "archivematica"
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
  container_port = 8080

  ecs_cluster_id = "${aws_ecs_cluster.archivematica.id}"

  vpc_id  = "${local.vpc_id}"
  subnets = "${local.network_private_subnets}"

  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"

  launch_type = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 200
}
