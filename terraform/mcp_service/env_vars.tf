module "mcp_client_env_vars" {
  source = "github.com/wellcometrust/terraform-modules.git//ecs/modules/task/modules/env_vars?ref=v19.12.0"

  env_vars        = "${var.mcp_client_env_vars}"
  env_vars_length = "${var.mcp_client_env_vars_length}"
}

module "mcp_client_secrets" {
  source = "github.com/wellcometrust/terraform-modules.git//ecs/modules/task/modules/secrets?ref=v19.12.0"

  secret_env_vars        = "${var.mcp_client_secret_env_vars}"
  secret_env_vars_length = "${var.mcp_client_secret_env_vars_length}"

  execution_role_name = "${module.iam_roles.task_execution_role_name}"
}
