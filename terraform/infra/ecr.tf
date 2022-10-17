resource "aws_ecr_repository" "services" {
  for_each = toset([
    "archivematica-mcp-client",
    "archivematica-mcp-server",
    "archivematica-dashboard",
    "archivematica-storage-service",
  ])

  name = "weco/${each.key}"
}

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

data "aws_ssm_parameter" "account_ids" {
  name = "/ecr/cross_account_pull_ids"
}

data "aws_iam_policy_document" "allow_cross_account_reads" {
  statement {
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]

    principals {
      type = "AWS"

      identifiers = [
        for account_id in split(",", data.aws_ssm_parameter.account_ids.value) :
        "arn:aws:iam::${account_id}:root"
      ]
    }
  }
}

resource "aws_ecr_repository_policy" "allow_cross_account_reads" {
  for_each = toset([
    aws_ecr_repository.clamavd.name,
    aws_ecr_repository.archivematica_dashboard.name,
    aws_ecr_repository.archivematica_dashboard_nginx.name,
    aws_ecr_repository.archivematica_mcp_client.name,
    aws_ecr_repository.archivematica_mcp_server.name,
    aws_ecr_repository.archivematica_storage_service_nginx.name,
    aws_ecr_repository.archivematica_storage_service.name,
  ])

  repository = each.key
  policy     = data.aws_iam_policy_document.allow_cross_account_reads.json
}
