module "mcp_client_env_vars" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//task_definition/modules/env_vars?ref=v1.0.0"

  env_vars = var.mcp_client_env_vars
}

module "mcp_client_secrets" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//task_definition/modules/secrets?ref=v1.0.0"

  secret_env_vars     = var.mcp_client_secret_env_vars
  execution_role_name = module.iam_roles.task_execution_role_name
}

module "mcp_server_env_vars" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//task_definition/modules/env_vars?ref=v1.0.0"

  env_vars = var.mcp_server_env_vars
}

module "mcp_server_secrets" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//task_definition/modules/secrets?ref=v1.0.0"

  secret_env_vars     = var.mcp_server_secret_env_vars
  execution_role_name = module.iam_roles.task_execution_role_name
}
