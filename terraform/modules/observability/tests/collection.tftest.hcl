# Mocked applies exercise the enabled -> disabled -> enabled lifecycle without
# credentials, a remote backend, or changes to AWS. Terraform >= 1.7 is required.
mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/mock" }
  }
  mock_resource "aws_ecs_task_definition" {
    defaults = { arn = "arn:aws:ecs:eu-west-1:123456789012:task-definition/mock:1" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-west-1:123456789012:log-group:/aws/events/archivematica-staging/lifecycle"
    }
  }
}

variables {
  collector_image    = "example.invalid/collector:0123456789012345678901234567890123456789"
  subnets            = ["subnet-0123456789abcdef0"]
  security_group_ids = ["sg-0123456789abcdef0"]
  enabled            = true
  environment        = "staging"
  region             = "eu-west-1"
  cluster_name       = "archivematica-staging"
  cluster_arn        = "arn:aws:ecs:eu-west-1:123456789012:cluster/archivematica-staging"
  ebs_volume_id      = "vol-0123456789abcdef0"
  ec2_instance_id    = "i-0123456789abcdef0"
  service_names      = ["am-staging-mcp_client", "am-staging-storage-service"]
}

run "enabled" {
  command = apply

  assert {
    condition     = length(aws_ecs_service.collector) == 1 && aws_ecs_service.collector[0].scheduling_strategy == "DAEMON"
    error_message = "Enabled monitoring must run a collector on each application host."
  }

  assert {
    condition     = alltrue([for mount in jsondecode(aws_ecs_task_definition.collector[0].container_definitions)[0].mountPoints : mount.readOnly])
    error_message = "Host evidence must be read-only."
  }

  assert {
    condition = alltrue([
      for name, paths in { root = ["/", "/hostfs"], ebs = ["/ebs", "/hostfs/ebs"] } :
      anytrue([for volume in aws_ecs_task_definition.collector[0].volume : volume.name == name && volume.host_path == paths[0]]) &&
      anytrue([for mount in jsondecode(aws_ecs_task_definition.collector[0].container_definitions)[0].mountPoints : mount.sourceVolume == name && mount.containerPath == paths[1] && mount.readOnly])
    ])
    error_message = "Root and shared-volume capacity must be read from the corresponding host filesystems."
  }

  assert {
    condition     = aws_cloudwatch_event_rule.lifecycle.state == "ENABLED"
    error_message = "Enabling monitoring must start lifecycle collection."
  }

  assert {
    condition = jsondecode(aws_cloudwatch_event_rule.lifecycle.event_pattern) == {
      source = ["aws.ecs"]
      "$or" = [
        {
          "detail-type" = ["ECS Task State Change", "ECS Service Action", "ECS Container Instance State Change"]
          detail        = { clusterArn = [var.cluster_arn] }
        },
        {
          "detail-type" = ["ECS Deployment State Change"]
          resources     = [{ prefix = "arn:aws:ecs:eu-west-1:123456789012:service/archivematica-staging/" }]
        }
      ]
    }
    error_message = "Host/task/service events must match clusterArn, while deployment events must match the cluster's service ARN without requiring clusterArn in detail."
  }

  assert {
    condition     = aws_cloudwatch_event_target.lifecycle.arn == aws_cloudwatch_log_group.lifecycle.arn && aws_cloudwatch_event_target.lifecycle.role_arn == null
    error_message = "EventBridge must deliver to the retained log group using its resource policy."
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_log_resource_policy.events.policy_document).Statement[0].Resource == "${aws_cloudwatch_log_group.lifecycle.arn}:*"
    error_message = "Event delivery permissions must be restricted to this environment's lifecycle log."
  }
}

run "disabled_preserves_history" {
  command = apply

  assert {
    condition     = length(aws_ecs_service.collector) == 0 && length(aws_ecs_task_definition.collector) == 0
    error_message = "Disabling monitoring must stop the collector."
  }
  assert {
    condition     = output.diagnostics_log_group_arn == run.enabled.diagnostics_log_group_arn && aws_cloudwatch_log_group.diagnostics.skip_destroy && aws_cloudwatch_log_group.diagnostics.retention_in_days == 90
    error_message = "Disabling monitoring must preserve detailed memory evidence."
  }
  variables {
    enabled = false
  }

  assert {
    condition     = aws_cloudwatch_event_rule.lifecycle.state == "DISABLED"
    error_message = "Disabling monitoring must stop new lifecycle collection."
  }

  assert {
    condition     = output.lifecycle_log_group_arn == run.enabled.lifecycle_log_group_arn && aws_cloudwatch_log_group.lifecycle.retention_in_days == 400 && aws_cloudwatch_log_group.lifecycle.skip_destroy
    error_message = "Disabling collection must retain the existing evidence and retention policy."
  }

  assert {
    condition     = output.dashboard_name == run.enabled.dashboard_name && strcontains(aws_cloudwatch_dashboard.operations.dashboard_body, "**disabled**")
    error_message = "The existing dashboard must remain available and show that collection is disabled."
  }

  assert {
    condition     = toset(aws_cloudwatch_query_definition.ebs_attachments.log_group_names) == toset([aws_cloudwatch_log_group.lifecycle.name])
    error_message = "Historical attachment lookup must remain available when collection is disabled."
  }
}

run "host_replaced_preserves_lookup" {
  command = apply
  variables {
    ec2_instance_id = "i-fedcba98765432100"
  }

  assert {
    condition     = output.lifecycle_log_group_arn == run.enabled.lifecycle_log_group_arn && aws_cloudwatch_log_group.lifecycle.skip_destroy
    error_message = "Changing the current host must preserve its predecessor's attachment events."
  }

  assert {
    condition = length([
      for setting in jsondecode(aws_cloudwatch_dashboard.operations.dashboard_body).variables : setting
      if try(setting.property == "InstanceId" && setting.inputType == "input" && setting.defaultValue == var.ec2_instance_id && setting.visible, false)
    ]) == 1
    error_message = "An arbitrary historical InstanceId must remain selectable beyond CloudWatch's discovery window, with the new host as the default."
  }

  assert {
    condition = alltrue([
      for name in ["VolumeThroughputExceededCheck", "VolumeIOPSExceededCheck"] :
      anytrue([
        for widget in jsondecode(aws_cloudwatch_dashboard.operations.dashboard_body).widgets :
        anytrue([
          for metric in try(widget.properties.metrics, []) :
          try(metric[0] == "AWS/EBS" && metric[1] == name && metric[2] == "VolumeId" && metric[3] == var.ebs_volume_id && metric[4] == "InstanceId" && metric[5] == var.ec2_instance_id, false)
        ])
      ])
    ])
    error_message = "Capacity checks require both VolumeId and the editable InstanceId."
  }
}

run "enabled_again" {
  command = apply
  variables {
    enabled = true
  }

  assert {
    condition     = output.lifecycle_log_group_arn == run.enabled.lifecycle_log_group_arn && aws_cloudwatch_event_rule.lifecycle.state == "ENABLED"
    error_message = "Re-enabling monitoring must reuse the retained log group."
  }

}
