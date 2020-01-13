locals {
  full_name = "am-${var.namespace}-gearman"
}

module "task_definition" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//task_definition/single_container?ref=v1.1.0"

  task_name = local.full_name

  container_image = var.container_image

  cpu    = var.cpu
  memory = var.memory

  mount_points = var.mount_points

  command = var.command

  env_vars        = var.env_vars
  secret_env_vars = var.secret_env_vars

  aws_region = var.aws_region
}

module "service" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//service?ref=v1.1.0"

  service_name = "gearman"
  cluster_arn  = var.cluster_arn

  desired_task_count = 1

  task_definition_arn = module.task_definition.arn

  subnets = var.network_private_subnets

  namespace_id = var.namespace_id

  security_group_ids = [
    var.interservice_security_group_id,
    var.service_egress_security_group_id,
    var.service_lb_security_group_id,
  ]

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}
