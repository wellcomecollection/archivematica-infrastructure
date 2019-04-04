module "iam_roles" {
  source    = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/iam_roles?ref=b59b32d"
  task_name = "mcp_worker"
}
