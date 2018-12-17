data "template_file" "container_definitions" {
  template = "${file("container_definitions.json")}"

  vars {
    dashboard_image = "${module.ecr_dashboard.repository_url}:${var.release_ids["archivematica_dashboard"]}"
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

  cpu    = 2048
  memory = 4096

}