locals {
  full_name = "am-${var.name}"

  nginx_cpu    = 128
  nginx_memory = 256
}

module "container_definition" {
  source = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/container_definition/container_with_sidecar?ref=b59b32d"

  aws_region = "${var.aws_region}"

  app_env_vars        = "${var.env_vars}"
  app_env_vars_length = "${var.env_vars_length}"

  secret_app_env_vars        = "${var.secret_env_vars}"
  secret_app_env_vars_length = "${var.secret_env_vars_length}"

  task_name = "${local.full_name}"

  log_group_prefix = "archivematica/${var.name}"

  app_container_image     = "${var.container_image}"
  sidecar_container_image = "${var.nginx_container_image}"

  sidecar_port_mappings_string = <<EOF
[
  {
    "ContainerPort": 80,
    "HostPort": 80,
    "Protocol": "tcp"
  }
]
EOF

  app_cpu    = "${var.cpu}"
  app_memory = "${var.memory}"

  sidecar_cpu    = "${local.nginx_cpu}"
  sidecar_memory = "${local.nginx_memory}"

  app_mount_points = "${var.mount_points}"

  execution_role_name = "${module.iam_roles.task_execution_role_name}"
}

module "iam_roles" {
  source    = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/iam_roles?ref=v19.11.0"
  task_name = "${local.full_name}"
}

resource "aws_ecs_task_definition" "task" {
  family                = "${local.full_name}"
  container_definitions = "${module.container_definition.rendered}"
  execution_role_arn    = "${module.iam_roles.task_execution_role_arn}"
  task_role_arn         = "${module.iam_roles.task_role_arn}"

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

  cpu    = "${var.cpu + local.nginx_cpu}"
  memory = "${var.memory + local.nginx_memory}"
}

module "service" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/service/prebuilt/load_balanced?ref=v11.3.1"

  service_name       = "${local.full_name}"
  task_desired_count = 1

  # The root paths return 302s which redirect to this login page.
  healthcheck_path = "${var.healthcheck_path}"

  container_name = "sidecar"
  container_port = 80

  task_definition_arn = "${aws_ecs_task_definition.task.arn}"

  security_group_ids = [
    "${local.interservice_security_group_id}",
    "${local.service_egress_security_group_id}",
    "${local.service_lb_security_group_id}",
  ]

  ecs_cluster_id = "${var.cluster_id}"

  vpc_id  = "${local.vpc_id}"
  subnets = "${local.network_private_subnets}"

  namespace_id = "${var.namespace_id}"

  launch_type = "EC2"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}

resource "aws_alb_listener_rule" "https" {
  listener_arn = "${var.load_balancer_https_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${module.service.target_group_arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.hostname}"]
  }
}
