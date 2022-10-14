output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
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
  value = aws_ecr_repository.archivematica_storage_service.repository_url
}
