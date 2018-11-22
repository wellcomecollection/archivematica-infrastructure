
resource "aws_ecs_cluster" "archivematica" {
  name = "${local.namespace}"
}
