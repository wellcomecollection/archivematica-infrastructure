resource "aws_ecs_task_definition" "archivematica" {
  family                = "archivematica"
  container_definitions = "${file("container_definitions.json")}"

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