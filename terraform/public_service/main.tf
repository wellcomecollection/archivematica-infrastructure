module "task" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/task/prebuilt/container_with_sidecar+ebs?ref=v16.1.6"

  aws_region = "${var.aws_region}"
  task_name  = "${var.name}"

  cpu    = "${var.cpu}"
  memory = "${var.memory}"

  log_group_prefix = "${var.log_group_prefix}"

  app_container_image = "${var.app_container_image}"
  app_container_port  = "${var.app_container_port}"

  app_cpu      = "${var.app_cpu}"
  app_memory   = "${var.app_memory}"
  app_env_vars = "${var.app_env_vars}"

  app_env_vars_length = "${var.app_env_vars_length}"

  sidecar_container_image = "${var.sidecar_container_image}"
  sidecar_container_port  = "${var.sidecar_container_port}"

  sidecar_cpu      = "${var.sidecar_cpu}"
  sidecar_memory   = "${var.sidecar_memory}"
  sidecar_env_vars = "${var.sidecar_env_vars}"

  sidecar_env_vars_length = "${var.sidecar_env_vars_length}"

  ebs_host_path      = "${var.ebs_host_path}"
  ebs_container_path = "${var.ebs_container_path}"

  sidecar_is_proxy = "true"
}

module "service" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecs/modules/service/prebuilt/rest/http?ref=v17.1.0"

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

  container_port = "${var.sidecar_container_port}"
  container_name = "${module.task.sidecar_task_name}"

  task_definition_arn = "${module.task.task_definition_arn}"

  healthcheck_path = "${var.healthcheck_path}"

  listener_port         = "80"
  lb_arn                = "${var.lb_arn}"

  launch_type = "EC2"
}
