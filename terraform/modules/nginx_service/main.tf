locals {
  full_name = "am-${var.name}"

  nginx_cpu    = 128
  nginx_memory = 256
}

module "task_definition" {
  source = "./container_with_sidecar"

  task_name = local.full_name

  cpu    = "${var.cpu + local.nginx_cpu}"
  memory = "${var.memory + local.nginx_memory}"

  app_container_image = var.container_image
  app_cpu             = var.cpu
  app_memory          = var.memory
  app_mount_points    = var.mount_points

  app_env_vars        = var.env_vars
  secret_app_env_vars = var.secret_env_vars

  sidecar_container_image = var.nginx_container_image
  sidecar_container_port  = 80
  sidecar_container_name  = "nginx"
  sidecar_cpu             = local.nginx_cpu
  sidecar_memory          = local.nginx_memory

  launch_type = "EC2"

  efs_host_path = local.efs_host_path

  aws_region = "eu-west-1"
}

module "service" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//service?ref=v1.0.0"

  service_name = local.full_name
  cluster_arn  = var.cluster_arn

  desired_task_count = 1

  task_definition_arn = module.task_definition.arn

  subnets = local.network_private_subnets

  namespace_id = var.namespace_id

  security_group_ids = [
    local.interservice_security_group_id,
    local.service_egress_security_group_id,
    local.service_lb_security_group_id,
  ]

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  launch_type = "EC2"

  target_group_arn = aws_alb_target_group.ecs_service.arn
  container_name = "sidecar"
  container_port = 80
}

resource "aws_alb_target_group" "ecs_service" {
  # We use snake case in a lot of places, but ALB Target Group names can
  # only contain alphanumerics and hyphens.
  name = "${replace(local.full_name, "_", "-")}"

  target_type = "ip"

  protocol = "HTTP"
  port     = 80
  vpc_id   = "${local.vpc_id}"

  # The root paths return 302s which redirect to this login page.
  health_check {
    protocol = "HTTP"
    path     = "${var.healthcheck_path}"
    matcher  = "200"
  }
}


resource "aws_alb_listener_rule" "https" {
  listener_arn = "${var.load_balancer_https_listener_arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.ecs_service.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.hostname}"]
  }
}
