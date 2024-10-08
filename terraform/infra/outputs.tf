output "certificate_arn" {
  value = module.cert.arn
}

output "ecr_dashboard_repo_url" {
  value = aws_ecr_repository.services["archivematica-dashboard"].repository_url
}

output "ecr_mcp_client_repo_url" {
  value = aws_ecr_repository.services["archivematica-mcp-client"].repository_url
}

output "ecr_mcp_server_repo_url" {
  value = aws_ecr_repository.services["archivematica-mcp-server"].repository_url
}

output "ecr_storage_service_repo_url" {
  value = aws_ecr_repository.services["archivematica-storage-service"].repository_url
}

output "ecr_nginx_repo_url" {
  value = aws_ecr_repository.services["archivematica-nginx"].repository_url
}

output "ecr_clamavd_repo_url" {
  value = aws_ecr_repository.services["clamavd"].repository_url
}
