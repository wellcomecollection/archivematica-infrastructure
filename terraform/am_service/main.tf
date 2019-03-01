locals {
  full_name = "am-${var.name}"
}

module "container_definition" {
  source = "../modules/single_container"

  aws_region = "${var.aws_region}"

  env_vars        = "${var.env_vars}"
  env_vars_length = "${var.env_vars_length}"

  task_name = "${local.full_name}"

  log_group_prefix = "archivematica/${var.name}"

  container_image = "${var.container_image}"

  command = "${var.command}"

  cpu    = "${var.cpu}"
  memory = "${var.memory}"

  mount_points = "${var.mount_points}"
}

module "iam_roles" {
  source    = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/iam_roles?ref=v17.1.0"
  task_name = "${local.full_name}"
}

resource "aws_ecs_task_definition" "task" {
  family                = "${local.full_name}"
  container_definitions = "${module.container_definition.rendered}"
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

  cpu    = "${var.cpu}"
  memory = "${var.memory}"
}

module "service" {
  source = "git::github.com/wellcometrust/terraform-modules//ecs/modules/service/prebuilt/default?ref=v19.0.0"

  service_name       = "${local.full_name}"
  task_desired_count = "1"

  task_definition_arn = "${aws_ecs_task_definition.task.arn}"

  security_group_ids = [
    "${local.interservice_security_group_id}",
    "${local.service_egress_security_group_id}",
    "${local.service_lb_security_group_id}",
  ]

  ecs_cluster_id = "${var.cluster_id}"

  subnets = "${local.network_private_subnets}"

  namespace_id = "${var.namespace_id}"

  launch_type = "EC2"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}
