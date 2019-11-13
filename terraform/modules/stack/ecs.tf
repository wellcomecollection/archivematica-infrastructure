resource "aws_ecs_cluster" "archivematica" {
  name = "archivematica-${var.namespace}"
}
