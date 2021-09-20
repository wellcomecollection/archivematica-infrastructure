module "log_router_container" {
  source    = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/firelens?ref=v3.11.0"
  namespace = var.service_name
}

module "log_router_container_secrets_permissions" {
  source    = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/secrets?ref=v3.11.0"
  secrets   = module.log_router_container.shared_secrets_logging
  role_name = module.task_definition.task_execution_role_name
}


module "task_definition" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/task_definition?ref=v3.11.0"

  cpu    = var.cpu
  memory = var.memory

  container_definitions = concat([
    module.log_router_container.container_definition,
  ], var.container_definitions)

  launch_types          = [var.launch_type]
  placement_constraints = var.placement_constraints
  volumes               = var.volumes

  task_name = var.service_name
}

module "service" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/service?ref=v3.11.0"

  cluster_arn  = var.cluster_arn
  service_name = var.service_name

  service_discovery_namespace_id = var.service_discovery_namespace_id

  task_definition_arn = module.task_definition.arn

  subnets            = var.subnets
  security_group_ids = var.security_group_ids

  desired_task_count = var.desired_task_count
  use_fargate_spot   = var.use_fargate_spot

  target_group_arn = var.target_group_arn

  deployment_service = var.deployment_service_name
  deployment_env     = var.deployment_service_env

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent

  container_name = var.container_name
  container_port = var.container_port

  launch_type = var.launch_type
}
