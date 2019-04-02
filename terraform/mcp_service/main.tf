locals {
  full_name = "am-mcp_client2"
}

data "template_file" "container_definition" {
  template = "${file("${path.module}/task_definition.json.template")}"

  vars {
    log_group_region = "eu-west-1"
    log_group_prefix = ""

    fits_cpu             = "${var.fits_cpu}"
    fits_memory          = "${var.fits_memory}"
    fits_container_image = "${var.fits_container_image}"
    fits_log_group_name  = "fits"
    fits_mount_points    = "${jsonencode(var.fits_mount_points)}"

    clamav_cpu             = "${var.clamav_cpu}"
    clamav_memory          = "${var.clamav_memory}"
    clamav_container_image = "${var.clamav_container_image}"
    clamav_log_group_name  = "clamav"
    clamav_mount_points    = "${jsonencode(var.clamav_mount_points)}"
  }
}

resource "aws_ecs_task_definition" "task" {
  family                = "${local.full_name}"
  container_definitions = "${data.template_file.container_definition.rendered}"
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

  cpu    = "${var.fits_cpu + var.clamav_cpu}"
  memory = "${var.fits_memory + var.clamav_memory}"
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
