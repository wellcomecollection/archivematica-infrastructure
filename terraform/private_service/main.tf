module "task" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/task/prebuilt/single_container+ebs?ref=v16.1.6"

  aws_region = "${var.aws_region}"
  task_name  = "${var.name}"

  cpu    = "${var.cpu}"
  memory = "${var.memory}"

  log_group_prefix = "${var.log_group_prefix}"

  container_image = "${var.container_image}"
  container_port  = "${var.container_port}"

  env_vars = "${var.env_vars}"

  env_vars_length = "${var.env_vars_length}"

  ebs_host_path      = "${var.ebs_host_path}"
  ebs_container_path = "${var.ebs_container_path}"
}

module "service" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/service/prebuilt/default?ref=v16.1.6"

  service_name       = "${var.name}"
  task_desired_count = "${var.task_desired_count}"

  security_group_ids = ["${var.security_group_ids}"]

  deployment_minimum_healthy_percent = "50"
  deployment_maximum_percent         = "200"

  ecs_cluster_id = "${var.cluster_id}"

  vpc_id = "${var.vpc_id}"

  subnets = [
    "${var.private_subnets}",
  ]

  namespace_id = "${var.namespace_id}"

  container_port = "${var.container_port}"

  task_definition_arn = "${module.task.task_definition_arn}"

  launch_type = "EC2"
}
