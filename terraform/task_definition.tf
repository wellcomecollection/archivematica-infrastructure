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
  network_mode             = "bridge"

  cpu    = 2048
  memory = 5120
}
