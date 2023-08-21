locals {
  full_name = "am-${var.namespace}-${var.name}"
}

module "service" {
  source = "../base"

  cluster_arn = var.cluster_arn

  container_definitions = [
    module.app_container.container_definition,
  ]

  service_discovery_namespace_id = var.namespace_id

  cpu    = var.cpu
  memory = var.memory

  desired_task_count = var.desired_task_count

  launch_type = "FARGATE"

  security_group_ids = [
    var.interservice_security_group_id,
    var.service_egress_security_group_id,
    var.service_lb_security_group_id
  ]

  service_name = local.full_name

  subnets = var.network_private_subnets

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  turn_off_outside_office_hours = var.turn_off_outside_office_hours
}

module "app_container" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/container_definition?ref=v3.13.1"
  name   = "app"

  image = var.container_image

  command = var.command

  environment = var.environment
  secrets     = var.secrets

  log_configuration = module.service.log_configuration
}

module "secrets" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/secrets?ref=v3.13.1"

  role_name = module.service.task_execution_role_name
  secrets   = var.secrets
}
