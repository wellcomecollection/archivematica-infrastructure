locals {
  full_name = "am-${var.namespace}-mcp_worker"
}

resource "aws_cloudwatch_log_group" "fits" {
  name = "ecs/am-${var.namespace}-fits"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "clamav" {
  name = "ecs/am-${var.namespace}-clamav"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "mcp_client" {
  name = "ecs/am-${var.namespace}-mcp_client"

  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "mcp_server" {
  name = "ecs/am-${var.namespace}-mcp_server"

  retention_in_days = 7
}

data "template_file" "container_definition" {
  template = file("${path.module}/task_definition.json.template")

  vars = {
    log_group_region = "eu-west-1"
    log_group_prefix = ""

    fits_cpu             = var.fits_cpu
    fits_memory          = var.fits_memory
    fits_container_image = var.fits_container_image
    fits_log_group_name  = aws_cloudwatch_log_group.fits.name
    fits_mount_points    = jsonencode(var.fits_mount_points)

    clamav_cpu             = var.clamav_cpu
    clamav_memory          = var.clamav_memory
    clamav_container_image = var.clamav_container_image
    clamav_log_group_name  = aws_cloudwatch_log_group.clamav.name
    clamav_mount_points    = jsonencode(var.clamav_mount_points)

    mcp_client_cpu             = var.mcp_client_cpu
    mcp_client_memory          = var.mcp_client_memory
    mcp_client_container_image = var.mcp_client_container_image
    mcp_client_log_group_name  = aws_cloudwatch_log_group.mcp_client.name
    mcp_client_env_vars        = module.mcp_client_env_vars.env_vars_string
    mcp_client_secrets         = module.mcp_client_secrets.env_vars_string
    mcp_client_mount_points    = jsonencode(var.mcp_client_mount_points)

    mcp_server_cpu             = var.mcp_server_cpu
    mcp_server_memory          = var.mcp_server_memory
    mcp_server_container_image = var.mcp_server_container_image
    mcp_server_log_group_name  = aws_cloudwatch_log_group.mcp_server.name
    mcp_server_env_vars        = module.mcp_server_env_vars.env_vars_string
    mcp_server_secrets         = module.mcp_server_secrets.env_vars_string
    mcp_server_mount_points    = jsonencode(var.mcp_server_mount_points)
  }
}

resource "aws_ecs_task_definition" "task" {
  family                = local.full_name
  container_definitions = data.template_file.container_definition.rendered
  execution_role_arn    = module.iam_roles.task_execution_role_arn

  network_mode = "awsvpc"

  # For now, using EBS/EFS means we need to be on EC2 instance.
  requires_compatibilities = ["EC2"]

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:efs.volume exists"
  }

  volume {
    name      = "location-data"
    host_path = "/efs/location-data"
  }

  volume {
    name      = "pipeline-data"
    host_path = "/efs/pipeline-data"
  }

  volume {
    name      = "staging-data"
    host_path = "/efs/staging-data"
  }

  cpu    = var.fits_cpu + var.clamav_cpu + var.mcp_client_cpu * 4 + var.mcp_server_cpu
  memory = var.fits_memory + var.clamav_memory + var.mcp_client_memory * 4 + var.mcp_server_memory
}

module "service" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service//service?ref=v1.1.0"

  service_name = local.full_name

  cluster_arn = var.cluster_arn

  desired_task_count = 1

  task_definition_arn = aws_ecs_task_definition.task.arn

  subnets = var.network_private_subnets

  namespace_id = var.namespace_id

  security_group_ids = [
    var.interservice_security_group_id,
    var.service_egress_security_group_id,
    var.service_lb_security_group_id,
  ]

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  launch_type = "EC2"
}
