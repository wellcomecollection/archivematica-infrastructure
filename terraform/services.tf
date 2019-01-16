locals {
  fits_service_hostname   = "${module.fits_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  clamav_service_hostname = "${module.clamav_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  gearmand_hostname       = "${module.gearmand_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"

  storage_service_host = "${module.storage_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  storage_service_port = 8000
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
  }

  env_vars_length = 8

  container_image = "${module.mcp_server_repo_uri.value}"

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    }
  ]

  cluster_id   = "${aws_ecs_cluster.archivematica.id}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}

module "mcp_client_service" {
  source = "./am_service"

  name = "mcp-client"

  env_vars = {
    DJANGO_SECRET_KEY                                              = "12345"
    DJANGO_SETTINGS_MODULE                                         = "settings.common"
    MAILGUN_SERVER                                                 = "${local.fits_service_hostname}"
    MAILGUN_PORT                                                   = "2113"
    ARCHIVEMATICA_MCPCLIENT_CLIENT_USER                            = "${module.rds_cluster.username}"
    ARCHIVEMATICA_MCPCLIENT_CLIENT_PASSWORD                        = "${module.rds_cluster.password}"
    ARCHIVEMATICA_MCPCLIENT_CLIENT_HOST                            = "${module.rds_cluster.host}"
    ARCHIVEMATICA_MCPCLIENT_CLIENT_PORT                            = "${module.rds_cluster.port}"
    ARCHIVEMATICA_MCPCLIENT_CLIENT_DATABASE                        = "MCP"
    ARCHIVEMATICA_MCPCLIENT_ELASTICSEARCHSERVER                    = "${aws_elasticsearch_domain.archivematica.endpoint}"
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_MCPARCHIVEMATICASERVER       = "${local.gearmand_hostname}:4730"
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_SEARCH_ENABLED               = true
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CAPTURE_CLIENT_SCRIPT_OUTPUT = true
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_SERVER                = "${local.clamav_service_hostname}:3310"
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_BACKEND        = "clamdscanner"
  }

  env_vars_length = 15

  container_image = "${module.mcp_client_repo_uri.value}"

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    }
  ]

  cluster_id   = "${aws_ecs_cluster.archivematica.id}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}

module "storage_service" {
  source = "./nginx_service"

  name = "storage-service"

  hostname         = "archivematica-storage-service.wellcomecollection.org"
  healthcheck_path = "/login/"

  env_vars = {
    FORWARDED_ALLOW_IPS       = "*"
    AM_GUNICORN_ACCESSLOG     = "/dev/null"
    AM_GUNICORN_RELOAD        = "true"
    AM_GUNICORN_RELOAD_ENGINE = "auto"
    DJANGO_SETTINGS_MODULE    = "storage_service.settings.local"
    SS_DBURL                  = "mysql://${module.rds_cluster.username}:${module.rds_cluster.password}@${module.rds_cluster.host}:${module.rds_cluster.port}/SS"
    SS_GNPUG_HOME_PATH        = "/var/archivematica/storage_service/.gnupg"
    SS_GUNICORN_BIND          = "0.0.0.0:${local.storage_service_port}"
  }

  env_vars_length = 8

  container_image = "${module.storage_service_repo_uri.value}"

  mount_points = [
    {
      sourceVolume  = "pipeline-data",
      containerPath = "/var/archivematica/sharedDirectory"
    },
    {
      sourceVolume  = "location-data",
      containerPath = "/home"
    },
    {
      sourceVolume  = "staging-data",
      containerPath = "/var/archivematica/storage_service"
    },
  ]

  nginx_container_image = "${module.storage_service_nginx_repo_uri.value}"

  load_balancer_https_listener_arn = "${module.lb_storage_service.https_listener_arn}"

  cluster_id   = "${aws_ecs_cluster.archivematica.id}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}

module "dashboard_service" {
  source = "./nginx_service"

  name = "dashboard"

  hostname         = "archivematica.wellcomecollection.org"
  healthcheck_path = "/administration/accounts/login/"

  env_vars = {
    FORWARDED_ALLOW_IPS                                    = "*"
    AM_GUNICORN_ACCESSLOG                                  = "/dev/null"
    AM_GUNICORN_RELOAD                                     = "true"
    AM_GUNICORN_RELOAD_ENGINE                              = "auto"
    ARCHIVEMATICA_DASHBOARD_DASHBOARD_GEARMAN_SERVER       = "${local.gearmand_hostname}:4730"
    ARCHIVEMATICA_DASHBOARD_DASHBOARD_ELASTICSEARCH_SERVER = "${aws_elasticsearch_domain.archivematica.endpoint}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_USER                    = "${module.rds_cluster.username}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_PASSWORD                = "${module.rds_cluster.password}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_HOST                    = "${module.rds_cluster.host}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_PORT                    = "${module.rds_cluster.port}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_DATABASE                = "MCP"
    ARCHIVEMATICA_DASHBOARD_SEARCH_ENABLED                 = "true"
    AM_GUNICORN_BIND                                       = "0.0.0.0:9000"
    WELLCOME_SS_URL                                        = "http://${local.storage_service_host}:${local.storage_service_port}"
    WELLCOME_SITE_URL                                      = "http://localhost:9000"
  }

  env_vars_length = 15

  container_image = "${module.dashboard_repo_uri.value}"

  mount_points = [
    {
      sourceVolume  = "pipeline-data",
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  nginx_container_image = "${module.dashboard_nginx_repo_uri.value}"

  load_balancer_https_listener_arn = "${module.lb_dashboard.https_listener_arn}"

  cluster_id   = "${aws_ecs_cluster.archivematica.id}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}