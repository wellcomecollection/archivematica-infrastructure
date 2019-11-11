module "task_role" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//task_definition/modules/iam_role?ref=v1.0.0"

  task_name = var.task_name
}

resource "aws_ecs_task_definition" "task" {
  family                = var.task_name
  container_definitions = data.template_file.container_definition.rendered

  task_role_arn      = module.task_role.task_role_arn
  execution_role_arn = module.task_role.task_execution_role_arn

  network_mode = "awsvpc"

  requires_compatibilities = [var.launch_type]

  cpu    = "${var.app_cpu + var.sidecar_cpu}"
  memory = "${var.app_memory + var.sidecar_memory}"

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
}
