locals {
  full_name = "am-${var.namespace}-${var.name}"
}

module "iam_roles" {
  source    = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//task_definition/modules/iam_role?ref=v1.0.0"
  task_name = "am-${local.full_name}"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "ecs/${local.full_name}"

  retention_in_days = 7
}

data "template_file" "container_definition" {
  template = file("${path.module}/task_definition.json.template")

  vars = {
    log_group_region = "eu-west-1"
    log_group_prefix = ""

    cpu             = var.cpu
    memory          = var.memory
    container_image = var.container_image
    log_group_name  = aws_cloudwatch_log_group.log_group.name
    mount_points    = jsonencode(var.mount_points)
    env_vars        = module.env_vars.env_vars_string
    secrets         = module.secrets.env_vars_string
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
    expression = "attribute:ebs.volume exists"
  }

  volume {
    name      = "pipeline-data"
    host_path = "/ebs/pipeline-data"
  }

  cpu    = var.cpu
  memory = var.memory
}

module "service" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service//service?ref=v1.1.0"

  service_name = local.full_name

  cluster_arn = var.cluster_arn

  desired_task_count = var.desired_task_count

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
