locals {
  ecr_policy_only_keep_the_last_100_images = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Only keep the last 100 images in a repo"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 100
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Keeps the images a deployment can reference, then only the newest few others, so Amazon Inspector scans what
# we run rather than months of builds. The stacks pin commit tags in locals.tf and can lag several builds
# behind, so 20 tagged images are kept rather than 10.
locals {
  ecr_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep env tagged images, e.g. env.prod"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["env."]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the latest tagged image"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 3
        description  = "Expire other tagged images, keep only the last 20"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = 20
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 4
        description  = "Expire untagged images, keep only the last 5"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_repository" "services" {
  for_each = toset([
    "archivematica-mcp-client",
    "archivematica-mcp-server",
    "archivematica-dashboard",
    "archivematica-storage-service",
    "archivematica-nginx",
    "archivematica-observability",
    "clamavd"
  ])

  name = "weco/${each.key}"
}

resource "aws_ecr_lifecycle_policy" "only_keep_the_last_100_images" {
  for_each = aws_ecr_repository.services

  repository = each.value.name
  # The stacks pin the observability image by digest, and a rebuild from the same commit leaves that digest
  # untagged, so it keeps the count-only rule.
  policy = each.key == "archivematica-observability" ? local.ecr_policy_only_keep_the_last_100_images : local.ecr_lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "legacy" {
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
  policy     = local.ecr_lifecycle_policy
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
