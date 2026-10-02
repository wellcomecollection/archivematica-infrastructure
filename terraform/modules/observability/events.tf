locals {
  name = "archivematica-${var.environment}"
}

# Never put retained evidence behind the enabled switch. skip_destroy also
# preserves the remote groups if this module is deliberately removed; reusing
# their names then requires importing them back into Terraform.
resource "aws_cloudwatch_log_group" "lifecycle" {
  name              = "/aws/events/${local.name}/lifecycle"
  retention_in_days = 400
  skip_destroy      = true
}

resource "aws_cloudwatch_event_rule" "lifecycle" {
  name        = "${local.name}-lifecycle"
  description = "Retain ECS host, task, service and deployment events for incident investigation."
  state       = var.enabled ? "ENABLED" : "DISABLED"
  event_pattern = jsonencode({
    source = ["aws.ecs"]
    "$or" = [
      {
        "detail-type" = ["ECS Task State Change", "ECS Service Action", "ECS Container Instance State Change"]
        detail        = { clusterArn = [var.cluster_arn] }
      },
      {
        # Deployment events omit detail.clusterArn; their service ARN carries
        # the cluster identity. The trailing slash excludes similarly named clusters.
        "detail-type" = ["ECS Deployment State Change"]
        resources     = [{ prefix = "${replace(var.cluster_arn, ":cluster/", ":service/")}/" }]
      }
    ]
  })
}

resource "aws_cloudwatch_log_resource_policy" "events" {
  policy_name = "${local.name}-lifecycle"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = ["events.amazonaws.com", "delivery.logs.amazonaws.com"] }
      Action    = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource  = "${aws_cloudwatch_log_group.lifecycle.arn}:*"
    }]
  })
}

resource "aws_cloudwatch_event_target" "lifecycle" {
  rule      = aws_cloudwatch_event_rule.lifecycle.name
  target_id = "retained-lifecycle-log"
  arn       = aws_cloudwatch_log_group.lifecycle.arn

  # Logs targets use a resource policy, not a target execution role.
  depends_on = [aws_cloudwatch_log_resource_policy.events]
}

resource "aws_cloudwatch_query_definition" "task_failures" {
  name            = "${local.name}/task-failures"
  log_group_names = [aws_cloudwatch_log_group.lifecycle.name]
  query_string    = <<-QUERY
    fields @timestamp, detail.taskArn, detail.stopCode, detail.stoppedReason, detail.containers
    | filter detail.lastStatus = "STOPPED"
    | sort @timestamp desc
    | limit 200
  QUERY
}

resource "aws_cloudwatch_query_definition" "deployments" {
  name            = "${local.name}/deployments-and-service-events"
  log_group_names = [aws_cloudwatch_log_group.lifecycle.name]
  query_string    = <<-QUERY
    fields @timestamp, `detail-type`, detail.eventName, detail.reason, @message
    | filter `detail-type` in ["ECS Deployment State Change", "ECS Service Action"]
    | sort @timestamp desc
    | limit 200
  QUERY
}

resource "aws_cloudwatch_query_definition" "ebs_attachments" {
  name            = "${local.name}/ebs-attachment-history"
  log_group_names = [aws_cloudwatch_log_group.lifecycle.name]
  query_string    = <<-QUERY
    filter `detail-type` = "ECS Container Instance State Change"
    | fields jsonParse(@message) as event
    | unnest event.detail.attributes into attribute
    | filter attribute.name = "ebs.volume"
    | fields event.detail.ec2InstanceId as instance_id, attribute.value as volume_attribute
    | parse volume_attribute /^(?<recorded_volume_id>vol-[0-9a-f]+)$/
    | fields coalesce(recorded_volume_id, "unknown") as volume_id
    | stats min(@timestamp) as first_seen, max(@timestamp) as last_seen by instance_id, volume_id, volume_attribute
    | sort last_seen desc
  QUERY
}
