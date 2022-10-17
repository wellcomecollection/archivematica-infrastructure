# Although we have a c5.4xlarge, which nominally only has a handful of ENIs,
# we use ENI trunking to allow us to run vastly more services on a single host.
# See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/container-instance-eni.html
locals {
  fits_cpu            = 3 * 1024
  mcp_server_cpu      = 1 * 1024
  nginx_cpu           = 128
  dashboard_cpu       = 1024
  storage_service_cpu = 1344

  total_dashboard_cpu       = local.dashboard_cpu + local.nginx_cpu
  total_storage_service_cpu = local.storage_service_cpu + local.nginx_cpu

  mcp_client_cpu = var.namespace == "prod" ? 1024 * 2 : 1024 * 1
  mcp_client_mem = var.namespace == "prod" ? 1024 * 4 : 1024 * 2

  mcp_client_count = 4
}

locals {
  fits_hostname     = "${module.fits_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  clamav_hostname   = "${module.clamav_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  gearmand_hostname = "${module.gearman_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"

  storage_service_host = "${module.storage_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  storage_service_port = 8000

  rds_archivematica_url = "mysql://${var.rds_username}:${var.rds_password}@${var.rds_host}:${var.rds_port}"
}

module "gearman_service" {
  source = "./fargate_service"

  name      = "gearman"
  namespace = var.namespace

  container_image = "artefactual/gearmand:1.1.18-alpine"

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
    {
      sourceVolume  = "tmp-data",
      containerPath = "/tmp"
    },
  ]

  cpu    = local.fits_cpu
  memory = 2048

  # See comment at top of the file about deployments.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace    = var.namespace
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}

module "clamav_service" {
  source = "./fargate_service"

  name = "clamav"

  container_image = var.clamavd_container_image

  cpu    = 2 * 1024
  memory = 4 * 1024

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

  environment = {
    ARCHIVEMATICA_MCPSERVER_CLIENT_USER     = var.rds_username
    ARCHIVEMATICA_MCPSERVER_CLIENT_PASSWORD = var.rds_password
    ARCHIVEMATICA_MCPSERVER_CLIENT_HOST     = var.rds_host
    ARCHIVEMATICA_MCPSERVER_CLIENT_PORT     = var.rds_port
    ARCHIVEMATICA_MCPSERVER_CLIENT_DATABASE = "MCP"

    ARCHIVEMATICA_MCPSERVER_MCPARCHIVEMATICASERVER = "${local.gearmand_hostname}:4730"

    # We don't enable indexing or search with Elasticsearch.  Data from the
    # storage service is indexed separately in the reporting cluster.
    ARCHIVEMATICA_MCPSERVER_MCPSERVER_SEARCH_ENABLED = false
  }

  secrets = {
    DJANGO_SECRET_KEY = "archivematica/mcp_server_django_secret_key"
  }

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
    {
      sourceVolume  = "tmp-data",
      containerPath = "/tmp"
    },
  ]

  cpu    = local.mcp_server_cpu
  memory = 2048

  # See comment at top of the file about deployments.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

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

  environment = {
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

    # This causes MCP client to stream files to ClamAV, rather than passing
    # it a path.  This means ClamAV doesn't need access to the shared
    # filesystem, and can run in Fargate, not on EC2.
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CLAMAV_PASS_BY_STREAM = true

    # This is a workaround for a persistent issue we saw where the MCP client
    # would timeout trying to connect to the storage service at the "Store AIP"
    # step of ingesting a large AIP (~2.7GB was the package we were using to
    # repro, but I suspect this wasn't the absolute threshhold).
    #
    # We've bumped the timeout to prevent this from happening, based on
    # discussion in this issue: https://github.com/archivematica/Issues/issues/114
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_STORAGE_SERVICE_CLIENT_QUICK_TIMEOUT = 600

    # This means we don't capture stdout/stderr from client script subprocesses.
    # This is an attempt to reduce the amount of data we have to write to
    # the database during transfers with lots of files, and reduce the
    # number of times we get the error (2006, ‘MySQL server has gone away’).
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_CAPTURE_CLIENT_SCRIPT_OUTPUT = true

    # We don't enable indexing or search with Elasticsearch.  Data from the
    # storage service is indexed separately in the reporting cluster.
    ARCHIVEMATICA_MCPCLIENT_MCPCLIENT_SEARCH_ENABLED = false
  }

  secrets = {
    DJANGO_SECRET_KEY = "archivematica/mcp_client_django_secret_key"
  }

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
    {
      sourceVolume  = "tmp-data",
      containerPath = "/tmp"
    },
  ]

  # The c5.4xlarge instances we use have 8 Elastic Network Interfaces, which
  # means they can run up to 8 of our ECS tasks simultaneously (because each
  # task needs an ENI).
  #
  # Those ENI slots are allocated as follows:
  #
  #   - ECS agent
  #   - Dashboard
  #   - Storage service
  #   - MCP server
  #   - Fits
  #   - (Spare slot)
  #
  # The spare slot is to allow the dashboard/storage service to spin up a second
  # task during deployments.
  #
  # That leaves two slots for the MCP client to run, and more clients
  # = better concurrency.
  desired_task_count = local.mcp_client_count

  cpu    = local.mcp_client_cpu
  memory = local.mcp_client_mem

  # See comment at top of the file about deployments.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

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

  namespace = var.namespace
  name      = "storage-service"

  hostname         = var.storage_service_hostname
  healthcheck_path = "/login/"

  # When the storage service is doing a CPU-intensive task (for example,
  # tar-gzipping an AIP before uploading it to the Wellcome Storage), it can
  # be slow to respond to requests.
  #
  # If it's too slow, the load balancer gets timeouts on healthcheck requests,
  # it assumes the task is unhealthy and stops the container, causing the ingest
  # to fail.  This timeout seems to make it less likely to get restarted when
  # it's doing something CPU-intensive.
  healthcheck_timeout = 120

  cpu    = local.storage_service_cpu
  memory = 4096

  environment = {
    FORWARDED_ALLOW_IPS       = "*"
    AM_GUNICORN_ACCESSLOG     = "/dev/null"
    AM_GUNICORN_RELOAD        = "true"
    AM_GUNICORN_RELOAD_ENGINE = "auto"
    SS_DB_URL                 = "${local.rds_archivematica_url}/SS"
    SS_GNPUG_HOME_PATH        = "/var/archivematica/storage_service/.gnupg"
    SS_GUNICORN_BIND          = "0.0.0.0:9000"
    DJANGO_ALLOWED_HOSTS      = "*"

    # The volume mounts are owned by "root".  By default gunicorn runs with
    # the 'archivematica' user, which can't access these mounts.
    SS_GUNICORN_USER = "root"

    SS_GUNICORN_GROUP = "root"

    # Multiple workers allow the dashboard to continue to serve web requests while
    # large downloads are in progress (these will occupy a whole worker process)
    # See https://github.com/wellcometrust/platform/issues/3954
    SS_GUNICORN_WORKERS = 4

    SS_OIDC_AUTHENTICATION = "true"
    AZURE_TENANT_ID        = var.azure_tenant_id
    OIDC_RP_CLIENT_ID      = var.oidc_client_id
    OIDC_RP_SIGN_ALGO      = "RS256"
  }

  secrets = {
    DJANGO_SECRET_KEY     = "archivematica/storage_service_django_secret_key"
    OIDC_RP_CLIENT_SECRET = "archivematica/${var.namespace}/oidc_rp_client_secret"
  }

  app_container_image   = var.storage_service_container_image
  nginx_container_image = var.nginx_container_image

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
    {
      sourceVolume  = "tmp-data",
      containerPath = "/tmp"
    },
  ]

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

  namespace = var.namespace
  name      = "dashboard"

  hostname         = var.dashboard_hostname
  healthcheck_path = "/administration/accounts/login/"

  cpu    = local.dashboard_cpu
  memory = 2048

  environment = {
    FORWARDED_ALLOW_IPS                              = "*"
    AM_GUNICORN_ACCESSLOG                            = "/dev/null"
    AM_GUNICORN_RELOAD                               = "true"
    AM_GUNICORN_RELOAD_ENGINE                        = "auto"
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

    # Multiple workers allow the dashboard to continue to serve web requests while
    # large downloads are in progress (these will occupy a whole worker process)
    # See https://github.com/wellcometrust/platform/issues/3954
    AM_GUNICORN_WORKERS = 4

    # The volume mounts are owned by "root".  By default gunicorn runs with
    # the 'archivematica' user, which can't access these mounts.
    AM_GUNICORN_USER = "root"

    # We don't enable indexing or search with Elasticsearch.  Data from the
    # storage service is indexed separately in the reporting cluster.
    ARCHIVEMATICA_DASHBOARD_DASHBOARD_SEARCH_ENABLED = false

    ARCHIVEMATICA_DASHBOARD_OIDC_AUTHENTICATION = "true"
    AZURE_TENANT_ID                             = var.azure_tenant_id
    OIDC_RP_CLIENT_ID                           = var.oidc_client_id
    OIDC_RP_SIGN_ALGO                           = "RS256"
  }

  secrets = {
    ARCHIVEMATICA_DASHBOARD_DJANGO_SECRET_KEY = "archivematica/dashboard_django_secret_key"
    OIDC_RP_CLIENT_SECRET                     = "archivematica/${var.namespace}/oidc_rp_client_secret"
  }

  app_container_image   = var.dashboard_container_image
  nginx_container_image = var.nginx_container_image

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]


  load_balancer_https_listener_arn = module.lb_dashboard.https_listener_arn

  cluster_arn  = aws_ecs_cluster.archivematica.arn
  namespace_id = aws_service_discovery_private_dns_namespace.archivematica.id

  vpc_id = var.vpc_id

  network_private_subnets = var.network_private_subnets

  interservice_security_group_id   = var.interservice_security_group_id
  service_egress_security_group_id = var.service_egress_security_group_id
  service_lb_security_group_id     = var.service_lb_security_group_id
}
