module "iam_roles" {
  source    = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//task_definition/modules/iam_role?ref=v1.0.0"
  task_name = "am-${var.namespace}-fits"
}
