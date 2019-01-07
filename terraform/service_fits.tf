module "fits_container_definition" {
  source = "git::github.com/wellcometrust/terraform-modules.git//ecs/modules/task/modules/container_definition/single_container?ref=v11.3.1"

  aws_region = "${var.region}"

  env_vars        = {}
  env_vars_length = 0

  task_name = "fits"

  log_group_prefix = "archivematica/fits"

  container_image = "artefactual/fits-ngserver:0.8.4"

  cpu    = 256
  memory = 512

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    }
  ]
}

resource "aws_ecs_task_definition" "fits" {
  family                = "archivematica-fits"
  container_definitions = "${module.fits_container_definition.rendered}"
  execution_role_arn    = "${module.iam_roles.task_execution_role_arn}"

  network_mode = "awsvpc"

  # For now, using EBS/EFS means we need to be on EC2 instance.
  requires_compatibilities = ["EC2"]

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:efs.volume exists"
  }

  volume {
    name      = "location-data"
    host_path = "${local.efs_host_path}/location-data"
  }

  volume {
    name      = "pipeline-data"
    host_path = "${local.efs_host_path}/pipeline-data"
  }

  volume {
    name      = "staging-data"
    host_path = "${local.efs_host_path}/staging-data"
  }

  cpu    = 256
  memory = 512
}

module "fits_service" {
  source = "git::github.com/wellcometrust/terraform-modules//ecs/modules/service/prebuilt/default?ref=unused-variables"

  service_name       = "archivematica-fits"
  task_desired_count = "1"

  task_definition_arn = "${aws_ecs_task_definition.fits.arn}"

  security_group_ids = [
    "${local.interservice_security_group_id}",
    "${local.service_egress_security_group_id}",
    "${local.service_lb_security_group_id}",
  ]

  ecs_cluster_id = "${aws_ecs_cluster.archivematica.id}"

  subnets = "${local.network_private_subnets}"

  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"

  launch_type = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
}


