locals {
  service_metrics = [for service in sort(tolist(var.service_names)) : [
    "AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", service
  ]]
}

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = local.name
  dashboard_body = jsonencode({
    start = "-PT6H"
    # A free-text dimension override keeps old attachments queryable even after
    # CloudWatch's two-week metric discovery window. Retained ECS host events
    # provide the historical ID; the current single host is only the default.
    variables = [{
      type    = "property", property = "InstanceId", inputType = "input"
      id      = "ebs_instance", label = "EBS instance ID", defaultValue = var.ec2_instance_id
      visible = true
    }]
    widgets = concat([
      {
        type = "text", x = 0, y = 0, width = 24, height = 3
        properties = {
          markdown = "# Archivematica ${var.environment}\nEnhanced collection: **${var.enabled ? "enabled" : "disabled"}**. Historical evidence remains available when collection is disabled; standard AWS metrics may continue. All timestamps in the saved queries are UTC.\nECS memory graphs exclude some file cache: they cannot establish memory charged against the task limit. The graphs below include application processing and enforced cgroup memory accounting. Missing samples mean unknown, not zero. No alerts are configured. [Application logs](https://logging.wellcomecollection.org/)"
        }
      },
      {
        type = "metric", x = 0, y = 3, width = 12, height = 6
        properties = {
          title   = "ECS service memory — incomplete cache accounting", region = var.region
          view    = "timeSeries", period = 300, stat = "Maximum"
          metrics = local.service_metrics
          yAxis   = { left = { min = 0, max = 100 } }
        }
      },
      {
        type = "metric", x = 12, y = 3, width = 12, height = 6
        properties = {
          title = "Running and pending ECS tasks", region = var.region
          view  = "timeSeries", period = 60, stat = "Average"
          metrics = concat(
            [for service in sort(tolist(var.service_names)) : ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", var.cluster_name, "ServiceName", service]],
            [for service in sort(tolist(var.service_names)) : ["ECS/ContainerInsights", "PendingTaskCount", "ClusterName", var.cluster_name, "ServiceName", service]]
          )
        }
      },
      {
        type = "metric", x = 0, y = 9, width = 12, height = 6
        properties = {
          title = "Shared EBS throughput (MiB/s)", region = var.region
          view  = "timeSeries", period = 60, stat = "Sum"
          metrics = [
            [{ expression = "read / PERIOD(read) / 1048576", label = "Read MiB/s", id = "readrate" }],
            [{ expression = "write / PERIOD(write) / 1048576", label = "Write MiB/s", id = "writerate" }],
            ["AWS/EBS", "VolumeReadBytes", "VolumeId", var.ebs_volume_id, { id = "read", visible = false }],
            ["AWS/EBS", "VolumeWriteBytes", "VolumeId", var.ebs_volume_id, { id = "write", visible = false }]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 9, width = 12, height = 6
        properties = {
          title = "Shared EBS queue and selected instance capacity checks", region = var.region
          view  = "timeSeries", period = 60, stat = "Maximum"
          metrics = [
            ["AWS/EBS", "VolumeQueueLength", "VolumeId", var.ebs_volume_id],
            ["AWS/EBS", "VolumeThroughputExceededCheck", "VolumeId", var.ebs_volume_id, "InstanceId", var.ec2_instance_id],
            ["AWS/EBS", "VolumeIOPSExceededCheck", "VolumeId", var.ebs_volume_id, "InstanceId", var.ec2_instance_id]
          ]
        }
      },
      {
        type = "log", x = 0, y = 15, width = 24, height = 6
        properties = {
          title = "Recent stopped tasks", region = var.region, view = "table"
          query = "SOURCE '${aws_cloudwatch_log_group.lifecycle.name}' | ${aws_cloudwatch_query_definition.task_failures.query_string}"
        }
      },
      {
        type = "text", x = 0, y = 21, width = 24, height = 5
        properties = {
          markdown = <<-MARKDOWN
            **Read processing activity** — [Operator guide]

            Active counts show unfinished work, not progress. Gearman batches awaiting results may be queued or running; the actual worker backlog is not measured.

            Completion rates, completion age and p95 describe finished work. Check collection coverage before interpreting gaps. Nonzero exits can be normal workflow decisions.

            After host replacement, find the incident's host in the saved **ebs-attachment-history** query and enter its **EBS instance ID** above.

            [Operator guide]: https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/docs/debugging-archivematica/monitoring.md
          MARKDOWN
        }
      }
    ], local.application_widgets)
  })
}
