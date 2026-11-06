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

  # A tag names the commit that defines its image, so it must never move: a moved tag lets the
  # lifecycle rules expire the digest a running task was started from.
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_lifecycle_policy" "only_keep_the_last_100_images" {
  for_each = aws_ecr_repository.services

  repository = each.value.name
  # The stacks pin the observability image by digest, and a rebuild from the same commit leaves that digest
  # untagged, so it keeps the count-only rule.
  policy = each.key == "archivematica-observability" ? local.ecr_policy_only_keep_the_last_100_images : local.ecr_lifecycle_policy
}
