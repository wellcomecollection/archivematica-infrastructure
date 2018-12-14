module "ecr_dashboard" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecr?ref=v1.0.0"
  name   = "archivematica_dashboard"
}

module "ecr_mcp_client" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecr?ref=v1.0.0"
  name   = "archivematica_mcp_client"
}

module "ecr_mcp_server" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecr?ref=v1.0.0"
  name   = "archivematica_mcp_server"
}

module "ecr_storage_service" {
  source = "git::https://github.com/wellcometrust/terraform.git//ecr?ref=v1.0.0"
  name   = "archivematica_storage_service"
}
