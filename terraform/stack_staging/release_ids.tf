module "dashboard_nginx_repo_uri" {
  source     = "../modules/ssm_repo_uri"
  image_name = "archivematica_dashboard_nginx"
}

module "storage_service_repo_uri" {
  source     = "../modules/ssm_repo_uri"
  image_name = "archivematica_storage_service"
}

module "storage_service_nginx_repo_uri" {
  source     = "../modules/ssm_repo_uri"
  image_name = "archivematica_storage_service_nginx"
}
