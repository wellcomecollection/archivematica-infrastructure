# This is an attempt at some rudimentary scaling: it turns off the
# container hosts outside working hours.
#
# Archivematica isn't a prod system and the EC2 instances we use are
# pretty expensive.  By my estimate, this will save ~$350/mo.

resource "aws_iam_role" "scheduler" {
  name               = "archivematica-${var.namespace}-instance-scheduler"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "allow_instance_scaling" {
  statement {
    actions = [
      "ec2:startInstances",
      "ec2:stopInstances",
    ]

    resources = module.cluster.ec2_instance_arns
  }
}

resource "aws_iam_role_policy" "allow_instance_scaling" {
  role   = aws_iam_role.scheduler.name
  policy = data.aws_iam_policy_document.allow_instance_scaling.json
}

resource "aws_scheduler_schedule" "instances_scale_up" {
  name       = "archivematica-${var.namespace}-instances-scale-up"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  # Run it each Monday
  schedule_expression = "cron(0 7 ? * MON,TUE,WED,THUR,FRI *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = module.cluster.ec2_instance_ids
    })
  }
}

resource "aws_scheduler_schedule" "instances_scale_down" {
  name       = "archivematica-${var.namespace}-instances-scale-down"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  # Run it each Monday
  schedule_expression = "cron(0 19 ? * MON,TUE,WED,THUR,FRI *)"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn

    input = jsonencode({
      InstanceIds = module.cluster.ec2_instance_ids
    })
  }
}
