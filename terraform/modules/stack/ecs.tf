# Keep this group outside the collection switch. Existing AWS-created groups
# must be imported before applying this configuration.
resource "aws_cloudwatch_log_group" "ecs_performance" {
  name              = "/aws/ecs/containerinsights/archivematica-${var.namespace}/performance"
  retention_in_days = 90
  skip_destroy      = true
}

resource "aws_ecs_cluster" "archivematica" {
  name = "archivematica-${var.namespace}"

  setting {
    name  = "containerInsights"
    value = var.observability_enabled ? "enhanced" : "disabled"
  }

  # Establish retention before ECS starts publishing.
  depends_on = [aws_cloudwatch_log_group.ecs_performance]
}
