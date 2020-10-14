locals {
  full_name = "am-${var.namespace}-${var.name}"

  host_port            = 80
  nginx_container_port = 80
  nginx_container_name = "nginx"
}

module "service" {
  source = "../base"

  cluster_arn = var.cluster_arn

  container_definitions = [
    module.app_container.container_definition,
    module.nginx_container.container_definition
  ]

  target_group_arn = aws_alb_target_group.ecs_service.arn
  container_port = local.nginx_container_port
  container_name = local.nginx_container_name

  service_discovery_namespace_id = var.namespace_id

  cpu = var.cpu
  memory = var.memory

  deployment_service_env  = var.namespace
  deployment_service_name = var.name

  desired_task_count = var.desired_task_count

  launch_type = "EC2"

  security_group_ids = [
    var.interservice_security_group_id,
    var.service_egress_security_group_id,
    var.service_lb_security_group_id
  ]

  service_name = local.full_name

  placement_constraints = [{
    type = "memberOf"
    expression = "attribute:ebs.volume exists"
  }]

  volumes = [
    {
      name      = "pipeline-data"
      host_path = "/ebs/pipeline-data"
    },
    {
      name      = "tmp-data"
      host_path = "/ebs/tmp/${var.name}"
    },
    {
      name      = "location-data"
      host_path = "/home"
    },
    {
      name      = "staging-data"
      host_path = "/var/archivematica/storage_service"
    },
  ]

  subnets = var.network_private_subnets

  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
}

module "app_container" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/container_definition?ref=v3.3.0"
  name   = "app"

  image = var.app_container_image

  environment  = var.environment
  secrets      = var.secrets
  mount_points = var.mount_points

  log_configuration = module.service.log_configuration
}

module "nginx_container" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/container_definition?ref=v3.3.0"
  name   = local.nginx_container_name

  image = var.nginx_container_image

  port_mappings = [{
    containerPort = local.nginx_container_port
    hostPort      = local.host_port
    protocol      = "tcp"
  }]

  log_configuration = module.service.log_configuration
}

module "secrets" {
  source = "git::github.com/wellcomecollection/terraform-aws-ecs-service.git//modules/secrets?ref=v3.3.0"

  role_name = module.service.task_execution_role_name
  secrets   = var.secrets
}

resource "aws_alb_target_group" "ecs_service" {
  # We use snake case in a lot of places, but ALB Target Group names can
  # only contain alphanumerics and hyphens.
  name = replace(local.full_name, "_", "-")

  target_type = "ip"

  protocol = "HTTP"
  port     = local.host_port
  vpc_id   = var.vpc_id

  # The root paths return 302s which redirect to this login page.
  health_check {
    protocol = "HTTP"
    path     = var.healthcheck_path
    matcher  = "200"

    # The default interval between healthchecks is 30 seconds.  If the interval
    # between checks is less than the timeout, you get an error from ECS:
    #
    #     Error modifying Target Group: ValidationError: Health check interval
    #     must be greater than the timeout.
    #
    # The interval is less important than the timeout, so just default it to
    # double the interval if the caller specifies a long timeout.
    timeout  = var.healthcheck_timeout
    interval = max(var.healthcheck_timeout * 2, 30)
  }
}


resource "aws_alb_listener_rule" "https" {
  listener_arn = var.load_balancer_https_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_service.arn
  }

  condition {
    host_header {
      values = [var.hostname]
    }
  }
}
