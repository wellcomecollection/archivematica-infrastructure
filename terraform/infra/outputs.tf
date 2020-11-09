output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
}

output "ecr_storage_service_repo_url" {
  value = aws_ecr_repository.archivematica_storage_service.repository_url
}
