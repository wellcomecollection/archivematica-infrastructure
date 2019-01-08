locals {
  gearmand_hostname   = "${module.gearmand_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  mcp_server_endpoint = "${module.mcp_server_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}:${local.mcp_server_port}"

  mcp_server_port = 8000
}

module "fits_service" {
  source = "./am_service"

  name = "fits"

  container_image = "artefactual/fits-ngserver:0.8.4"

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    }
  ]

  cluster_id   = "${aws_ecs_cluster.archivematica.id}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}

module "clamav_service" {
  source = "./am_service"

  name = "clamav"

  cpu    = 256
  memory = 1024

  container_image = "artefactual/clamav:latest"

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    }
  ]

  cluster_id   = "${aws_ecs_cluster.archivematica.id}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}

module "gearmand_service" {
  source = "./am_service"

  name = "gearmand"

  container_image = "artefactual/gearmand:1.1.17-alpine"

  command = [
    "--queue-type=redis",
    "--redis-server=${aws_elasticache_cluster.archivematica.cache_nodes.0.address}",
    "--redis-port=${aws_elasticache_cluster.archivematica.cache_nodes.0.port}",
  ]

  cluster_id   = "${aws_ecs_cluster.archivematica.id}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}

module "mcp_server_service" {
  source = "./am_service"

  name = "mcp-server"

  env_vars = {
    DJANGO_SECRET_KEY                       = "12345"
    ARCHIVEMATICA_MCPSERVER_CLIENT_USER     = "${module.rds_cluster.username}"
    ARCHIVEMATICA_MCPSERVER_CLIENT_PASSWORD = "${module.rds_cluster.password}"
    ARCHIVEMATICA_MCPSERVER_CLIENT_HOST     = "${module.rds_cluster.host}"
    ARCHIVEMATICA_MCPSERVER_CLIENT_PORT     = "${module.rds_cluster.port}"
    ARCHIVEMATICA_MCPSERVER_CLIENT_DATABASE = "MCP"

    ARCHIVEMATICA_MCPSERVER_MCPSERVER_MCPARCHIVEMATICA_SERVER = "${local.gearmand_hostname}:4730"

    ARCHIVEMATICA_MCPSERVER_SEARCH_ENABLED = true

    SS_GUNICORN_BIND = "0.0.0.0:${local.mcp_server_port}"
  }

  env_vars_length = 9

  container_image = "${module.ecr_mcp_server.repository_url}:${var.release_ids["archivematica_mcp_server"]}"

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    }
  ]

  cluster_id   = "${aws_ecs_cluster.archivematica.id}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}

