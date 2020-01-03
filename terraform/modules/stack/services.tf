locals {
  fits_hostname     = "${module.fits_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  clamav_hostname   = "${module.clamav_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  gearmand_hostname = "${module.gearman_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"

  storage_service_host = "${module.storage_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  storage_service_port = 8000

  rds_archivematica_url = "mysql://${var.rds_username}:${var.rds_password}@${var.rds_host}:${var.rds_port}"
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

  cpu    = 512
  memory = 1024

  cluster_arn  = aws_ecs_cluster.archivematica.id
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}

module "fits_service" {
  source = "./ec2_service"

  name = "fits"

  container_image = "artefactual/fits-ngserver:0.8.4"

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  cpu    = 3072
  memory = 4096

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace    = var.namespace
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}

module "clamav_service" {
  source = "./ec2_service"

  name = "clamav"

  container_image = "artefactual/clamav:latest"

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  cpu    = 2048
  memory = 2048

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace    = var.namespace
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}

module "mcp_server_service" {
  source = "./ec2_service"

  name = "mcp_server"

  container_image = var.mcp_server_container_image

  env_vars = {
    ARCHIVEMATICA_MCPSERVER_CLIENT_USER     = var.rds_username
    ARCHIVEMATICA_MCPSERVER_CLIENT_PASSWORD = var.rds_password
    ARCHIVEMATICA_MCPSERVER_CLIENT_HOST     = var.rds_host
    ARCHIVEMATICA_MCPSERVER_CLIENT_PORT     = var.rds_port
    ARCHIVEMATICA_MCPSERVER_CLIENT_DATABASE = "MCP"

    ARCHIVEMATICA_MCPSERVER_MCPARCHIVEMATICASERVER = "${local.gearmand_hostname}:4730"
  }

  secret_env_vars = {
    DJANGO_SECRET_KEY = "archivematica/mcp_server_django_secret_key"
  }

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  cpu    = 2048
  memory = 2048

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace    = var.namespace
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}

module "mcp_client_service" {
  source = "./ec2_service"

  name = "mcp_client"

  container_image = var.mcp_client_container_image

  env_vars = {
    DJANGO_SETTINGS_MODULE                                         = "settings.common"
    NAILGUN_SERVER                                                 = local.fits_hostname
    NAILGUN_PORT                                                   = "2113"
    ARCHIVEMATICA_MCPCLIENT_CLIENT_USER                            = var.rds_username
    ARCHIVEMATICA_MCPCLIENT_CLIENT_PASSWORD                        = var.rds_password
    ARCHIVEMATICA_MCPCLIENT_CLIENT_HOST                            = var.rds_host
    ARCHIVEMATICA_MCPCLIENT_CLIENT_PORT                            = var.rds_port
    ARCHIVEMATICA_MCPCLIENT_CLIENT_DATABASE                        = "MCP"
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_MCPARCHIVEMATICASERVER       = "${local.gearmand_hostname}:4730"
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CAPTURE_CLIENT_SCRIPT_OUTPUT = true
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_SERVER                = "${local.clamav_hostname}:3310"
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_CLIENT_BACKEND        = "clamdscanner"
  }

  secret_env_vars = {
    DJANGO_SECRET_KEY                           = "archivematica/mcp_client_django_secret_key"
    ARCHIVEMATICA_MCPCLIENT_ELASTICSEARCHSERVER = "archivematica/${var.namespace}/elasticsearch_url"
  }

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  cpu    = 3072
  memory = 3072

  desired_task_count = 1

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace    = var.namespace
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}

module "storage_service" {
  source = "./nginx_service"

  name = "am-${var.namespace}-storage-service"

  hostname         = var.storage_service_hostname
  healthcheck_path = "/login/"

  cpu    = 1024
  memory = 1024

  env_vars = {
    FORWARDED_ALLOW_IPS       = "*"
    AM_GUNICORN_ACCESSLOG     = "/dev/null"
    AM_GUNICORN_RELOAD        = "true"
    AM_GUNICORN_RELOAD_ENGINE = "auto"
    SS_DB_URL                 = "${local.rds_archivematica_url}/SS"
    SS_GNPUG_HOME_PATH        = "/var/archivematica/storage_service/.gnupg"
    SS_GUNICORN_BIND          = "0.0.0.0:${local.storage_service_port}"
    DJANGO_ALLOWED_HOSTS      = "*"

    # The volume mounts are owned by "root".  By default gunicorn runs with
    # the 'archivematica' user, which can't access these mounts.
    SS_GUNICORN_USER = "root"

    SS_GUNICORN_GROUP = "root"

    SS_OIDC_AUTHENTICATION    = "true"
    AZURE_TENANT_ID           = var.azure_tenant_id
    OIDC_RP_CLIENT_ID         = var.oidc_client_id
    OIDC_RP_SIGN_ALGO         = "RS256"
  }

  secret_env_vars = {
    DJANGO_SECRET_KEY = "archivematica/storage_service_django_secret_key"
    OIDC_RP_CLIENT_SECRET = "archivematica/${var.namespace}/oidc_rp_client_secret"
  }

  container_image = var.storage_service_container_image

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
    {
      sourceVolume  = "location-data"
      containerPath = "/home"
    },
    {
      sourceVolume  = "staging-data"
      containerPath = "/var/archivematica/storage_service"
    },
  ]

  nginx_container_image = var.storage_service_nginx_container_image

  load_balancer_https_listener_arn = module.lb_storage_service.https_listener_arn

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  vpc_id = var.vpc_id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}

module "dashboard_service" {
  source = "./nginx_service"

  name = "am-${var.namespace}-dashboard"

  hostname         = var.dashboard_hostname
  healthcheck_path = "/administration/accounts/login/"

  cpu    = 1024
  memory = 1024

  env_vars = {
    FORWARDED_ALLOW_IPS                              = "*"
    AM_GUNICORN_ACCESSLOG                            = "/dev/null"
    AM_GUNICORN_RELOAD                               = "true"
    AM_GUNICORN_RELOAD_ENGINE                        = "auto"
    # Multiple workers allow the dashboard to continue to serve web requests while
    # large downloads are in progress (these will occupy a whole worker process)
    # See https://github.com/wellcometrust/platform/issues/3954
    AM_GUNICORN_WORKERS                              = 4
    ARCHIVEMATICA_DASHBOARD_DASHBOARD_GEARMAN_SERVER = "${local.gearmand_hostname}:4730"
    ARCHIVEMATICA_DASHBOARD_CLIENT_USER              = var.rds_username
    ARCHIVEMATICA_DASHBOARD_CLIENT_PASSWORD          = var.rds_password
    ARCHIVEMATICA_DASHBOARD_CLIENT_HOST              = var.rds_host
    ARCHIVEMATICA_DASHBOARD_CLIENT_PORT              = var.rds_port
    ARCHIVEMATICA_DASHBOARD_CLIENT_DATABASE          = "MCP"
    ARCHIVEMATICA_DASHBOARD_DJANGO_ALLOWED_HOSTS     = "*"
    AM_GUNICORN_BIND                                 = "0.0.0.0:9000"
    WELLCOME_SS_URL                                  = "http://${local.storage_service_host}:${local.storage_service_port}"
    WELLCOME_SITE_URL                                = "http://localhost:9000"

    # The volume mounts are owned by "root".  By default gunicorn runs with
    # the 'archivematica' user, which can't access these mounts.
    AM_GUNICORN_USER = "root"

    ARCHIVEMATICA_DASHBOARD_OIDC_AUTHENTICATION              = "true"
    AZURE_TENANT_ID                                          = var.azure_tenant_id
    OIDC_RP_CLIENT_ID                                        = var.oidc_client_id
    OIDC_RP_SIGN_ALGO                                        = "RS256"
  }

  secret_env_vars = {
    ARCHIVEMATICA_DASHBOARD_DJANGO_SECRET_KEY              = "archivematica/dashboard_django_secret_key"
    ARCHIVEMATICA_DASHBOARD_DASHBOARD_ELASTICSEARCH_SERVER = "archivematica/${var.namespace}/elasticsearch_url"
    OIDC_RP_CLIENT_SECRET                                  = "archivematica/${var.namespace}/oidc_rp_client_secret"
  }

  container_image = var.dashboard_container_image

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  nginx_container_image = var.dashboard_nginx_container_image

  load_balancer_https_listener_arn = module.lb_dashboard.https_listener_arn

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  vpc_id = var.vpc_id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}
