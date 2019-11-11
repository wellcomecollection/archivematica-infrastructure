locals {
  gearmand_hostname = "${module.gearman_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
}

module "gearman_service" {
  source = "./gearman_service"

  namespace = var.namespace

  container_image = "artefactual/gearmand:1.1.17-alpine"

  command = [
    "--queue-type=redis",
    "--redis-server=${var.redis_server}",
    "--redis-port=${var.redis_port}",
  ]

  cluster_arn  = aws_ecs_cluster.archivematica.id
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}

module "mcp_worker_service" {
  source = "./mcp_worker"

  namespace = var.namespace

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  fits_container_image = "artefactual/fits-ngserver:0.8.4"

  fits_mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  clamav_container_image = "artefactual/clamav:latest"

  clamav_mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  mcp_client_env_vars = {
    DJANGO_SETTINGS_MODULE                                         = "settings.common"
    NAILGUN_SERVER                                                 = "localhost"
    NAILGUN_PORT                                                   = "2113"
    ARCHIVEMATICA_MCPCLIENT_CLIENT_USER                            = var.rds_username
    ARCHIVEMATICA_MCPCLIENT_CLIENT_PASSWORD                        = var.rds_password
    ARCHIVEMATICA_MCPCLIENT_CLIENT_HOST                            = var.rds_host
    ARCHIVEMATICA_MCPCLIENT_CLIENT_PORT                            = var.rds_port
    ARCHIVEMATICA_MCPCLIENT_CLIENT_DATABASE                        = "MCP"
    ARCHIVEMATICA_MCPCLIENT_ELASTICSEARCHSERVER                    = var.elasticsearch_url
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_MCPARCHIVEMATICASERVER       = "${local.gearmand_hostname}:4730"
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CAPTURE_CLIENT_SCRIPT_OUTPUT = true
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_SERVER                = "localhost:3310"
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_BACKEND        = "clamdscanner"
  }

  mcp_client_secret_env_vars = {
    DJANGO_SECRET_KEY = "archivematica/mcp_client_django_secret_key"
  }

  mcp_client_container_image = var.mcp_client_container_image

  mcp_client_mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  mcp_server_env_vars = {
    ARCHIVEMATICA_MCPSERVER_CLIENT_USER     = var.rds_username
    ARCHIVEMATICA_MCPSERVER_CLIENT_PASSWORD = var.rds_password
    ARCHIVEMATICA_MCPSERVER_CLIENT_HOST     = var.rds_host
    ARCHIVEMATICA_MCPSERVER_CLIENT_PORT     = var.rds_port
    ARCHIVEMATICA_MCPSERVER_CLIENT_DATABASE = "MCP"

    ARCHIVEMATICA_MCPSERVER_MCPARCHIVEMATICASERVER = "${local.gearmand_hostname}:4730"
  }

  mcp_server_secret_env_vars = {
    DJANGO_SECRET_KEY = "archivematica/mcp_server_django_secret_key"
  }

  mcp_server_container_image = var.mcp_server_container_image

  mcp_server_mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}