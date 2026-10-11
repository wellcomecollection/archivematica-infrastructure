variable "collector_image" {
  description = "Published collector image with an immutable tag or digest. Required when collection is enabled."
  type        = string
  default     = null
  validation {
    condition     = var.collector_image == null ? true : can(regex("(@sha256:[a-f0-9]{64}|:[a-f0-9]{40})$", var.collector_image))
    error_message = "Use a collector image pinned by SHA-256 digest or a full Git commit tag."
  }
}

variable "subnets" {
  type    = list(string)
  default = []
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

resource "aws_cloudwatch_log_group" "diagnostics" {
  name              = "/archivematica/${var.environment}/observability"
  retention_in_days = 90
  skip_destroy      = true
}

locals {
  task_trust = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole"
      Condition = { StringEquals = { "aws:SourceAccount" = split(":", var.cluster_arn)[4] } }
    }]
  })
}

resource "aws_iam_role" "collector" {
  name               = "${local.name}-observability"
  assume_role_policy = local.task_trust
}

resource "aws_iam_role_policy" "collector" {
  role = aws_iam_role.collector.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow", Action = ["ecs:ListTasks"], Resource = "*"
        Condition = { ArnEquals = { "ecs:cluster" = var.cluster_arn } }
      },
      {
        Effect   = "Allow", Action = ["ecs:DescribeTasks"]
        Resource = "${replace(var.cluster_arn, ":cluster/", ":task/")}/*"
      },
      # CloudWatch OTLP uses the standard metric ingestion permission.
      { Effect = "Allow", Action = ["cloudwatch:PutMetricData"], Resource = "*" }
    ]
  })
}

resource "aws_iam_role" "collector_execution" {
  name               = "${local.name}-observability-execution"
  assume_role_policy = local.task_trust
}

resource "aws_iam_role_policy_attachment" "collector_execution" {
  role       = aws_iam_role.collector_execution.name
  policy_arn = "arn:${split(":", var.cluster_arn)[1]}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "collector" {
  count = var.enabled ? 1 : 0

  family                   = "${local.name}-observability"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.collector.arn
  execution_role_arn       = aws_iam_role.collector_execution.arn

  dynamic "volume" {
    for_each = { proc = "/proc", sys = "/sys", ebs = "/ebs" }
    content {
      name      = volume.key
      host_path = volume.value
    }
  }

  container_definitions = jsonencode([{
    name                   = "collector", image = coalesce(var.collector_image, "unconfigured"), essential = true
    user                   = "10001:10001"
    readonlyRootFilesystem = true
    # Match the empty defaults returned by ECS to avoid repeated replacements.
    portMappings   = []
    systemControls = []
    volumesFrom    = []
    environment = [
      { name = "ENVIRONMENT", value = var.environment },
      { name = "AWS_REGION", value = var.region },
      { name = "AWS_DEFAULT_REGION", value = var.region },
      { name = "AWS_EC2_METADATA_DISABLED", value = "true" },
      { name = "OTEL_CONFIG", value = jsonencode(local.otel_config) }
    ]
    mountPoints = [for name in ["proc", "sys", "ebs"] : {
      sourceVolume = name, containerPath = "/hostfs/${name}", readOnly = true
    }]
    linuxParameters = {
      capabilities       = { add = [], drop = ["ALL"] }
      initProcessEnabled = true
      tmpfs = [{
        containerPath = "/tmp", size = 64
        mountOptions  = ["rw", "nosuid", "nodev", "noexec", "mode=1777"]
      }]
    }
    stopTimeout = 30
    healthCheck = {
      command  = ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:9401/health',timeout=3)"]
      interval = 30, timeout = 5, retries = 3, startPeriod = 120
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.diagnostics.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "collector"
      }
    }
  }])

  lifecycle {
    precondition {
      condition     = var.collector_image != null && length(var.subnets) > 0 && length(var.security_group_ids) > 0
      error_message = "Enabled monitoring requires a published immutable collector image and private task networking."
    }
  }
}

resource "aws_ecs_service" "collector" {
  count = var.enabled ? 1 : 0

  name                = "${local.name}-observability"
  cluster             = var.cluster_arn
  task_definition     = aws_ecs_task_definition.collector[0].arn
  launch_type         = "EC2"
  scheduling_strategy = "DAEMON"

  # One collector per host; avoid double ingestion during replacement.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ebs.volume exists"
  }

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  depends_on = [aws_iam_role_policy.collector, aws_iam_role_policy_attachment.collector_execution]
}
