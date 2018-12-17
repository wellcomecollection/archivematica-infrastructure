data "template_file" "container_definitions" {
  template = "${file("container_definitions.json")}"

  vars {
    dashboard_image       = "${module.ecr_dashboard.repository_url}:${var.release_ids["archivematica_dashboard"]}",
    mcp_client_image      = "${module.ecr_mcp_client.repository_url}:${var.release_ids["archivematica_mcp_client"]}"
    mcp_server_image      = "${module.ecr_mcp_server.repository_url}:${var.release_ids["archivematica_mcp_server"]}"
    storage_service_image = "${module.ecr_storage_service.repository_url}:${var.release_ids["archivematica_storage_service"]}"
  }
}

resource "aws_ecs_task_definition" "archivematica" {
  family                = "archivematica"
  container_definitions = "${data.template_file.container_definitions.rendered}"

  volume {
    name      = "pipeline-data"
    host_path = "/ecs/pipeline-data"
  }

  volume {
    name      = "location-data"
    host_path = "/ecs/location-data"
  }

  volume {
    name      = "staging-data"
    host_path = "/ecs/staging-data"
  }

  cpu    = 2048
  memory = 4096
}
