module "dashboard_repo_uri" {
  source     = "ssm_repo_uri"
  image_name = "dashboard"
}

module "mcp_client_repo_uri" {
  source     = "ssm_repo_uri"
  image_name = "archivematica_mcp_client"
}

module "mcp_server_repo_uri" {
  source     = "ssm_repo_uri"
  image_name = "archivematica_mcp_server"
}

module "storage_service_repo_uri" {
  source     = "ssm_repo_uri"
  image_name = "archivematica_storage_service"
}

module "storage_service_nginx_repo_uri" {
  source     = "ssm_repo_uri"
  image_name = "archivematica_storage_service_nginx"
}
