locals {
  fits_name = "am2-fits"
}

module "iam_roles" {
  source    = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/iam_roles?ref=b59b32d"
  task_name = "mcp_service"
}

module "fits_iam_roles" {
  source    = "github.com/wellcometrust/terraform.git//ecs/modules/task/modules/iam_roles?ref=b59b32d"
  task_name = "${local.fits_name}"
}
