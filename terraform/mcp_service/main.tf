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
  }
}

resource "aws_ecs_task_definition" "task" {
  family                = "mcp_service"
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
    host_path = "${var.efs_host_path}/location-data"
  }

  volume {
    name      = "pipeline-data"
    host_path = "${var.efs_host_path}/pipeline-data"
  }

  volume {
    name      = "staging-data"
    host_path = "${var.efs_host_path}/staging-data"
  }

  cpu    = "${var.fits_cpu}"
  memory = "${var.fits_memory}"
}
