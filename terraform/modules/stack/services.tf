# Currently we run the Archivematica tasks on a c5.4xlarge instance, which
# has ~16 vCPUs available, or 16384 CPU units (16 × 1024).
#
# We need to balance the following factors:
#
#   * minimising idle CPU (because the MCP client in particular is very CPU-hungry,
#     and the more CPU we can allocate, the faster transfers will go through)
#
#   * being able to deploy tasks automatically
#
# The dashboard and storage service are both user-facing apps, so they should
# have zero-downtime deployments.  We need to leave enough CPU idle that we can
# spin up new instances of those tasks.
#
# Gearman and ClamAV run in Fargate, so we don't need to worry about them.
#
# For the other tasks, we can allow a brief period of downtime while we're
# deploying new versions, and so claim back some extra CPU.  This setting:
#
#     deployment_minimum_healthy_percent = 0
#
# will tell ECS that it's okay to scale back to zero when deploying new tasks,
# and then we don't need so much idling CPU.
#
# Our CPU allocations need to satisfy the following constraint:
#
#     (fits_cpu + mcp_server_cpu + mcp_client_cpu) +
#     (dashboard_cpu + storage_service_cpu) + 128 * 3 +
#     max(dashboard_cpu, storage_service_cpu)
#      <= 16384
#
# (Because we allocate 128 CPU units to our nginx containers.  We have to count
# the two running instances, and the third instance creating during a deployment.)
#
# For more information, see:
# https://github.com/wellcomecollection/docs/blob/master/research/2020-01-14-ecs-scaling-big-tasks.md
#
# Note: a c5.4xlarge has 32GB of memory, which gives us way more headroom and
# isn't a deployment bottleneck.  We don't need to manage it as carefully.

locals {
  fits_cpu       = 3 * 1024
  mcp_server_cpu = 1 * 1024
  mcp_client_cpu = 16384 - (3 * 1024 + 1 * 1024 + 1024 + 1600 + 3 * 128 + 1600)
  dashboard_cpu       = 1024
  storage_service_cpu = 1600
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
    {
      sourceVolume  = "tmp-data",
      containerPath = "/tmp"
    },
  ]

  cpu    = local.fits_cpu
  memory = 4096

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

  container_image = "artefactual/clamav:latest"

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
    {
      sourceVolume  = "tmp-data",
      containerPath = "/tmp"
    },
  ]

  cpu    = local.mcp_client_cpu
  memory = 6 * 1024

  # See comment at top of the file about deployments.
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

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

  namespace = "am-${var.namespace}"
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
  memory = 2048

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
    {
      sourceVolume  = "tmp-data",
      containerPath = "/tmp"
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

  namespace = "am-${var.namespace}"
  name      = "dashboard"

  hostname         = var.dashboard_hostname
  healthcheck_path = "/administration/accounts/login/"

  cpu    = local.dashboard_cpu
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
