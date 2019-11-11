locals {
  gearmand_hostname = "${module.gearman_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"

  storage_service_host = "${module.storage_service.service_name}.${aws_service_discovery_private_dns_namespace.archivematica.name}"
  storage_service_port = 8000
}

module "storage_service" {
  source = "./modules/nginx_service"

  name = "storage-service"

  hostname         = "archivematica-storage-service.wellcomecollection.org"
  healthcheck_path = "/login/"

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
  }

  env_vars_length = 10

  secret_env_vars = {
    DJANGO_SECRET_KEY = "archivematica/storage_service_django_secret_key"
  }

  secret_env_vars_length = 1

  container_image = "${module.storage_service_repo_uri.value}"

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

  nginx_container_image = "${module.storage_service_nginx_repo_uri.value}"

  load_balancer_https_listener_arn = "${module.lb_storage_service.https_listener_arn}"

  cluster_arn  = "${aws_ecs_cluster.archivematica.arn}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}

module "dashboard_service" {
  source = "./modules/nginx_service"

  name = "dashboard"

  hostname         = "archivematica.wellcomecollection.org"
  healthcheck_path = "/administration/accounts/login/"

  env_vars = {
    FORWARDED_ALLOW_IPS                                    = "*"
    AM_GUNICORN_ACCESSLOG                                  = "/dev/null"
    AM_GUNICORN_RELOAD                                     = "true"
    AM_GUNICORN_RELOAD_ENGINE                              = "auto"
    # Multiple workers allow the dashboard to continue to serve web requests while
    # large downloads are in progress (these will occupy a whole worker process)
    # See https://github.com/wellcometrust/platform/issues/3954
    AM_GUNICORN_WORKERS                                    = 4
    ARCHIVEMATICA_DASHBOARD_DASHBOARD_GEARMAN_SERVER       = "${local.gearmand_hostname}:4730"
    ARCHIVEMATICA_DASHBOARD_DASHBOARD_ELASTICSEARCH_SERVER = "${local.elasticsearch_url}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_USER                    = "${local.rds_username}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_PASSWORD                = "${local.rds_password}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_HOST                    = "${local.rds_host}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_PORT                    = "${local.rds_port}"
    ARCHIVEMATICA_DASHBOARD_CLIENT_DATABASE                = "MCP"
    ARCHIVEMATICA_DASHBOARD_DJANGO_ALLOWED_HOSTS           = "*"
    AM_GUNICORN_BIND                                       = "0.0.0.0:9000"
    WELLCOME_SS_URL                                        = "http://${local.storage_service_host}:${local.storage_service_port}"
    WELLCOME_SITE_URL                                      = "http://localhost:9000"

    # The volume mounts are owned by "root".  By default gunicorn runs with
    # the 'archivematica' user, which can't access these mounts.
    AM_GUNICORN_USER = "root"
  }

  env_vars_length = 17

  secret_env_vars = {
    ARCHIVEMATICA_DASHBOARD_DJANGO_SECRET_KEY = "archivematica/dashboard_django_secret_key"
  }

  secret_env_vars_length = 1

  container_image = "${module.dashboard_repo_uri.value}"

  mount_points = [
    {
      sourceVolume  = "pipeline-data"
      containerPath = "/var/archivematica/sharedDirectory"
    },
  ]

  nginx_container_image = "${module.dashboard_nginx_repo_uri.value}"

  load_balancer_https_listener_arn = "${module.lb_dashboard.https_listener_arn}"

  cluster_arn  = "${aws_ecs_cluster.archivematica.arn}"
  namespace_id = "${aws_service_discovery_private_dns_namespace.archivematica.id}"
}
