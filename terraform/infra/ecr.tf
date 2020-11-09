resource "aws_ecr_repository" "clamavd" {
  name = "uk.ac.wellcome/clamavd"
}

resource "aws_ecr_repository" "archivematica_dashboard" {
  name = "uk.ac.wellcome/archivematica_dashboard"
}

resource "aws_ecr_repository" "archivematica_dashboard_nginx" {
  name = "uk.ac.wellcome/archivematica_dashboard_nginx"
}

resource "aws_ecr_repository" "archivematica_mcp_client" {
  name = "uk.ac.wellcome/archivematica_mcp_client"
}

resource "aws_ecr_repository" "archivematica_mcp_server" {
  name = "uk.ac.wellcome/archivematica_mcp_server"
}

resource "aws_ecr_repository" "archivematica_storage_service_nginx" {
  name = "uk.ac.wellcome/archivematica_storage_service_nginx"
}

resource "aws_ecr_repository" "archivematica_storage_service" {
  name = "uk.ac.wellcome/archivematica_storage_service"
}
